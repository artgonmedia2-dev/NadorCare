import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../catalogue/catalogue_providers.dart';
import '../patients/patient_texts.dart';
import '../patients/patients_providers.dart';
import 'bookings_providers.dart';
import 'price_breakdown.dart';

enum _Step { patient, address, slot, summary, done }

/// Réservation d'un soin en quatre écrans, un seul choix par écran (cahier des charges §11) :
/// le patient, l'adresse, le créneau, puis la vérification et l'envoi. Le soin a déjà été choisi.
class BookingFlowScreen extends ConsumerStatefulWidget {
  const BookingFlowScreen({required this.serviceSlug, super.key});

  final String serviceSlug;

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  static const String _asap = 'asap';

  final TextEditingController _note = TextEditingController();

  _Step _step = _Step.patient;
  String? _profileId;
  String? _addressId;
  DateTime _day = DateTime.now();

  /// `'asap'`, ou le début du créneau choisi.
  String? _slotChoice;
  BookingSlot? _slot;

  String? _prescriptionFileId;
  bool _uploading = false;
  bool _sending = false;
  String? _error;
  Booking? _created;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _go(_Step step) => setState(() {
        _step = step;
        _error = null;
      });

  void _back() {
    switch (_step) {
      case _Step.patient || _Step.done:
        context.pop();
      case _Step.address:
        _go(_Step.patient);
      case _Step.slot:
        _go(_Step.address);
      case _Step.summary:
        _go(_Step.slot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(careServiceProvider(widget.serviceSlug));

    return PopScope(
      canPop: _step == _Step.patient || _step == _Step.done,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _back();
        }
      },
      child: switch (service) {
        AsyncData<CareService>(:final value) => switch (_step) {
            _Step.patient => _patientStep(context),
            _Step.address => _addressStep(context),
            _Step.slot => _slotStep(context, value),
            _Step.summary => _summaryStep(context, value),
            _Step.done => _doneStep(context),
          },
        AsyncError<CareService>(:final error) => NcPage(
            appBar: AppBar(),
            title: context.l10n.bookService,
            actions: <Widget>[
              NcPrimaryButton(
                label: context.l10n.retry,
                onPressed: () => ref.invalidate(careServiceProvider(widget.serviceSlug)),
              ),
            ],
            children: <Widget>[NcNotice(message: failureMessage(context, error), kind: NcNoticeKind.error)],
          ),
        _ => NcPage(
            appBar: AppBar(),
            title: context.l10n.bookService,
            children: const <Widget>[Center(child: CircularProgressIndicator())],
          ),
      },
    );
  }

  PreferredSizeWidget _appBar() => AppBar(leading: BackButton(onPressed: _back));

  /// Les quatre écrans du parcours annoncent où l'on en est.
  Widget _progress(int current) =>
      NcStepIndicator(label: context.l10n.stepProgress(current, 4), current: current, total: 4);

  List<Widget> _errorNotice() => <Widget>[
        if (_error != null) ...<Widget>[
          NcNotice(message: _error!, kind: NcNoticeKind.error),
          const SizedBox(height: NcSpacing.md),
        ],
      ];

  // --- 1. Patient ---

  Widget _patientStep(BuildContext context) {
    final l10n = context.l10n;
    final profiles = ref.watch(profilesControllerProvider);
    final list = profiles.value ?? const <PatientProfile>[];

    return NcPage(
      appBar: _appBar(),
      title: l10n.bookingStepPatientTitle,
      actions: <Widget>[
        if (list.isNotEmpty)
          NcPrimaryButton(
            label: l10n.continueButton,
            onPressed: () {
              if (_profileId == null) {
                setState(() => _error = l10n.bookingChoosePatient);
              } else {
                _go(_Step.address);
              }
            },
          ),
        if (list.isEmpty)
          NcPrimaryButton(
            label: l10n.profileAdd,
            icon: Icons.person_add_alt,
            onPressed: () => context.push(routeProfileNew),
          )
        else
          NcSecondaryButton(
            label: l10n.profileAdd,
            icon: Icons.person_add_alt,
            onPressed: () => context.push(routeProfileNew),
          ),
      ],
      children: <Widget>[
        _progress(1),
        ..._errorNotice(),
        if (profiles.isLoading && list.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (profiles.hasError && list.isEmpty)
          NcNotice(message: failureMessage(context, profiles.error!), kind: NcNoticeKind.error)
        else if (list.isEmpty)
          NcEmptyState(message: l10n.bookingNoProfile, icon: Icons.person_outline)
        else
          NcChoiceList<String>(
            keyPrefix: 'booking-profile',
            selected: _profileId,
            onSelected: (id) => setState(() {
              _profileId = id;
              _error = null;
            }),
            choices: <NcChoice<String>>[
              for (final profile in list) NcChoice<String>(value: profile.id, label: profile.fullName),
            ],
          ),
      ],
    );
  }

  // --- 2. Adresse ---

  Widget _addressStep(BuildContext context) {
    final l10n = context.l10n;
    final addresses = ref.watch(addressesControllerProvider);
    final list = addresses.value ?? const <PatientAddress>[];

    return NcPage(
      appBar: _appBar(),
      title: l10n.bookingStepAddressTitle,
      actions: <Widget>[
        if (list.isNotEmpty)
          NcPrimaryButton(
            label: l10n.continueButton,
            onPressed: () {
              final chosen = list.where((address) => address.id == _addressId).firstOrNull;
              if (chosen == null) {
                setState(() => _error = l10n.bookingChooseAddress);
              } else if (!chosen.isCovered) {
                setState(() => _error = l10n.bookingAddressNotCovered);
              } else {
                _go(_Step.slot);
              }
            },
          ),
        if (list.isEmpty)
          NcPrimaryButton(
            label: l10n.addressAdd,
            icon: Icons.add_location_alt_outlined,
            onPressed: () => context.push(routeAddressNew),
          )
        else
          NcSecondaryButton(
            label: l10n.addressAdd,
            icon: Icons.add_location_alt_outlined,
            onPressed: () => context.push(routeAddressNew),
          ),
      ],
      children: <Widget>[
        _progress(2),
        ..._errorNotice(),
        if (addresses.isLoading && list.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (addresses.hasError && list.isEmpty)
          NcNotice(message: failureMessage(context, addresses.error!), kind: NcNoticeKind.error)
        else if (list.isEmpty)
          NcEmptyState(message: l10n.bookingNoAddress, icon: Icons.home_outlined)
        else
          NcChoiceList<String>(
            keyPrefix: 'booking-address',
            selected: _addressId,
            onSelected: (id) => setState(() {
              _addressId = id;
              _error = null;
            }),
            choices: <NcChoice<String>>[
              for (final address in list)
                NcChoice<String>(
                  value: address.id,
                  label: address.isCovered
                      ? '${address.label}\n${address.line}'
                      : '${address.label}\n${address.line}\n${l10n.addressNotCovered}',
                ),
            ],
          ),
      ],
    );
  }

  // --- 3. Créneau ---

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null && mounted) {
      setState(() {
        _day = picked;
        _slotChoice = null;
        _slot = null;
        _error = null;
      });
    }
  }

  Widget _slotStep(BuildContext context, CareService service) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final DayQuery query = (serviceId: service.id, date: apiDate(_day));
    final day = ref.watch(bookingDayProvider(query));
    final loaded = day.value;
    final isToday = apiDate(_day) == apiDate(DateTime.now());

    return NcPage(
      appBar: _appBar(),
      title: l10n.bookingStepSlotTitle,
      subtitle: l10n.slotNadorTime,
      actions: <Widget>[
        NcPrimaryButton(
          label: l10n.continueButton,
          onPressed: () {
            if (_slotChoice == null) {
              setState(() => _error = l10n.slotChoose);
            } else {
              _go(_Step.summary);
            }
          },
        ),
      ],
      children: <Widget>[
        _progress(3),
        ..._errorNotice(),
        NcSecondaryButton(
          key: const ValueKey<String>('booking-day-button'),
          icon: Icons.event_outlined,
          label: longDate(_day, language),
          onPressed: _pickDay,
        ),
        const SizedBox(height: NcSpacing.md),
        if (day.hasError)
          ...<Widget>[
            NcNotice(message: failureMessage(context, day.error!), kind: NcNoticeKind.error),
            const SizedBox(height: NcSpacing.md),
            NcSecondaryButton(label: l10n.retry, onPressed: () => ref.invalidate(bookingDayProvider(query))),
          ]
        else if (loaded == null)
          const Center(child: CircularProgressIndicator())
        else if (loaded.slots.isEmpty && !(isToday && loaded.immediateAvailable))
          NcEmptyState(message: l10n.slotNone, icon: Icons.event_busy_outlined)
        else
          NcChoiceList<String>(
            keyPrefix: 'booking-slot',
            selected: _slotChoice,
            onSelected: (choice) => setState(() {
              _slotChoice = choice;
              _slot = loaded.slots.where((slot) => slot.startsAt == choice).firstOrNull;
              _error = null;
            }),
            choices: <NcChoice<String>>[
              if (isToday && loaded.immediateAvailable) NcChoice<String>(value: _asap, label: l10n.slotAsap),
              for (final slot in loaded.slots) NcChoice<String>(value: slot.startsAt, label: slot.time),
            ],
          ),
      ],
    );
  }

  // --- 4. Vérification et envoi ---

  Future<void> _addPrescription({required bool fromCamera}) async {
    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final picked = await ref.read(prescriptionPickerProvider).pick(fromCamera: fromCamera);
      if (picked == null) {
        return;
      }
      final id = await ref.read(bookingsApiProvider).uploadPrescription(bytes: picked.bytes, filename: picked.filename);
      if (mounted) {
        setState(() => _prescriptionFileId = id);
      }
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failure.firstErrorFor('file') ?? failureMessage(context, failure));
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _send(CareService service) async {
    final l10n = context.l10n;

    if (service.requiresPrescription && _prescriptionFileId == null) {
      setState(() => _error = l10n.prescriptionMissing);
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final booking = await ref.read(bookingsApiProvider).create(
            BookingDraft(
              serviceId: service.id,
              patientProfileId: _profileId!,
              addressId: _addressId!,
              slot: _slot,
              patientNote: _note.text.trim(),
              prescriptionFileId: _prescriptionFileId,
              // Personne n'est sur place pour encaisser une téléconsultation : elle se règle par carte.
              paymentMethod: service.isRemote ? 'card' : 'cash',
            ),
          );
      ref.invalidate(bookingsListProvider);
      if (mounted) {
        setState(() {
          _created = booking;
          _step = _Step.done;
        });
      }
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failureMessage(context, failure));
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Widget _summaryStep(BuildContext context, CareService service) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;

    final profile = (ref.watch(profilesControllerProvider).value ?? const <PatientProfile>[])
        .where((item) => item.id == _profileId)
        .firstOrNull;
    final address = (ref.watch(addressesControllerProvider).value ?? const <PatientAddress>[])
        .where((item) => item.id == _addressId)
        .firstOrNull;

    final QuoteQuery quoteQuery = (serviceId: service.id, slot: _slot);
    final quote = ref.watch(bookingQuoteProvider(quoteQuery));
    final slot = _slot;

    return NcPage(
      appBar: _appBar(),
      title: l10n.bookingStepSummaryTitle,
      actions: <Widget>[
        NcPrimaryButton(
          label: l10n.bookingConfirm,
          isLoading: _sending,
          onPressed: _uploading ? null : () => _send(service),
        ),
      ],
      children: <Widget>[
        _progress(4),
        ..._errorNotice(),
        NcSurface(
          margin: const EdgeInsets.only(bottom: NcSpacing.md),
          padding: const EdgeInsets.symmetric(horizontal: NcSpacing.md, vertical: NcSpacing.sm),
          child: Column(
            children: <Widget>[
              SummaryRow(icon: Icons.medical_services_outlined, label: l10n.summaryService, value: service.name),
              SummaryRow(icon: Icons.person_outline, label: l10n.summaryPatient, value: profile?.fullName ?? ''),
              SummaryRow(
                icon: Icons.place_outlined,
                label: l10n.summaryAddress,
                value: address == null ? '' : '${address.label}\n${address.line}',
              ),
              SummaryRow(
                icon: Icons.event_outlined,
                label: l10n.summarySlot,
                value: slot == null ? l10n.slotAsap : l10n.dateAtTime(longDate(_day, language), slot.time),
              ),
              SummaryRow(
                icon: Icons.payments_outlined,
                label: l10n.summaryPayment,
                value: service.isRemote ? l10n.paymentCard : l10n.paymentCash,
              ),
            ],
          ),
        ),
        switch (quote) {
          AsyncData<PriceQuote>(:final value) => NcSurface(child: PriceBreakdown(price: value)),
          AsyncError<PriceQuote>(:final error) => NcNotice(
              message: failureMessage(context, error),
              kind: NcNoticeKind.error,
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
        const SizedBox(height: NcSpacing.lg),
        if (service.requiresPrescription) ...<Widget>[
          NcSectionTitle(l10n.servicePrescriptionRequired),
          if (_prescriptionFileId != null)
            NcNotice(key: const ValueKey<String>('prescription-added'), message: l10n.prescriptionAdded)
          else if (_uploading)
            const Center(child: CircularProgressIndicator())
          else ...<Widget>[
            NcSecondaryButton(
              key: const ValueKey<String>('prescription-camera'),
              label: l10n.prescriptionCamera,
              icon: Icons.photo_camera_outlined,
              onPressed: () => _addPrescription(fromCamera: true),
            ),
            const SizedBox(height: NcSpacing.sm),
            NcSecondaryButton(
              key: const ValueKey<String>('prescription-gallery'),
              label: l10n.prescriptionGallery,
              icon: Icons.photo_library_outlined,
              onPressed: () => _addPrescription(fromCamera: false),
            ),
          ],
          const SizedBox(height: NcSpacing.lg),
        ],
        NcSectionTitle(l10n.noteLabel),
        TextField(
          key: const ValueKey<String>('booking-note'),
          controller: _note,
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l10n.noteHint),
        ),
      ],
    );
  }

  // --- Confirmation ---

  Widget _doneStep(BuildContext context) {
    final l10n = context.l10n;
    final booking = _created!;

    return NcPage(
      title: l10n.bookingSentTitle,
      // Le numéro reste lisible de gauche à droite dans une phrase en arabe.
      subtitle: l10n.bookingSentBody(isolateLtr(booking.reference)),
      actions: <Widget>[
        NcPrimaryButton(label: l10n.bookingSeeMine, onPressed: () => context.go(routeBookings)),
      ],
      children: <Widget>[
        Center(
          child: Container(
            width: 144,
            height: 144,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, size: 80, color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: NcSpacing.lg),
        NcNotice(message: l10n.statusPending),
        const SizedBox(height: NcSpacing.md),
        NcNotice(message: l10n.emergencyNotice, kind: NcNoticeKind.warning),
      ],
    );
  }
}
