import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../auth/auth_controller.dart';
import '../failure_message.dart';
import '../providers.dart';

enum _Step { phone, code, consent }

/// Connexion ou inscription en trois écrans au plus, un seul choix par écran :
/// numéro de téléphone, code reçu par SMS, puis consentement si le compte est nouveau.
class LoginFlow extends ConsumerStatefulWidget {
  const LoginFlow({super.key});

  @override
  ConsumerState<LoginFlow> createState() => _LoginFlowState();
}

class _LoginFlowState extends ConsumerState<LoginFlow> {
  static const int _codeLength = 6;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  _Step _step = _Step.phone;
  bool _busy = false;
  String? _error;
  String? _fieldError;
  String? _info;
  int _resendIn = 0;
  Timer? _timer;

  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _acceptHealthData = false;

  /// Entoure un texte des marques Unicode « isolat gauche-à-droite » (U+2066 … U+2069).
  static String _isolateLtr(String text) => '${String.fromCharCode(0x2066)}$text${String.fromCharCode(0x2069)}';

  AuthController get _auth => ref.read(authControllerProvider.notifier);

  bool get _isPatientApp => ref.read(appConfigProvider).clientApp == ClientApp.patient;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _resendIn = seconds);
    if (seconds <= 0) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendIn = _resendIn - 1);
      if (_resendIn <= 0) {
        timer.cancel();
      }
    });
  }

  /// Lance une action réseau en gérant l'attente et l'affichage de l'erreur.
  Future<void> _run(Future<void> Function() action, {void Function(ApiFailure failure)? onFailure}) async {
    setState(() {
      _busy = true;
      _error = null;
      _fieldError = null;
      _info = null;
    });

    try {
      await action();
    } on ApiFailure catch (failure) {
      if (!mounted) {
        return;
      }
      if (onFailure != null) {
        onFailure(failure);
      } else {
        setState(() => _error = failureMessage(context, failure));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _sendCode({bool isResend = false}) async {
    final phone = _phoneController.text.trim();

    if (phone.replaceAll(RegExp(r'\D'), '').length < 8) {
      setState(() => _fieldError = context.l10n.phoneInvalid);
      return;
    }

    await _run(
      () async {
        final challenge = await _auth.requestOtp(phone);
        if (!mounted) {
          return;
        }
        _codeController.clear();
        setState(() {
          _step = _Step.code;
          _info = isResend ? context.l10n.codeResent : null;
        });
        _startCountdown(challenge.resendIn);
      },
      onFailure: (failure) {
        if (failure.code == ApiFailure.otpTooSoon) {
          // Un code a déjà été envoyé il y a un instant : on passe à sa saisie.
          setState(() => _step = _Step.code);
          _startCountdown(failure.retryAfterSeconds ?? 60);
          return;
        }
        setState(() {
          _fieldError = failure.firstErrorFor('phone');
          _error = _fieldError == null ? failureMessage(context, failure) : null;
        });
      },
    );
  }

  Future<void> _verify({required bool acceptTerms}) async {
    final code = _codeController.text.trim();

    if (code.length != _codeLength) {
      setState(() {
        _step = _Step.code;
        _fieldError = context.l10n.otpIncomplete;
      });
      return;
    }

    await _run(
      () => _auth.verifyOtp(phone: _phoneController.text.trim(), code: code, acceptTerms: acceptTerms),
      onFailure: (failure) {
        if (failure.code == ApiFailure.consentRequired && !acceptTerms) {
          // Numéro inconnu : le code reste valable, on demande le consentement.
          setState(() => _step = _Step.consent);
          return;
        }
        setState(() {
          // Code refusé depuis l'écran de consentement : retour à la saisie du code.
          _step = _Step.code;
          _error = failureMessage(context, failure);
        });
      },
    );
  }

  void _backToPhone() {
    _timer?.cancel();
    setState(() {
      _step = _Step.phone;
      _error = null;
      _fieldError = null;
      _info = null;
      _resendIn = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _Step.phone,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _backToPhone();
        }
      },
      child: switch (_step) {
        _Step.phone => _buildPhone(context),
        _Step.code => _buildCode(context),
        _Step.consent => _buildConsent(context),
      },
    );
  }

  List<Widget> _messages() {
    return <Widget>[
      if (_info != null) ...<Widget>[NcNotice(message: _info!), const SizedBox(height: NcSpacing.md)],
      if (_error != null) ...<Widget>[
        NcNotice(message: _error!, kind: NcNoticeKind.error),
        const SizedBox(height: NcSpacing.md),
      ],
    ];
  }

  Widget _buildPhone(BuildContext context) {
    final l10n = context.l10n;

    return NcPage(
      title: l10n.phoneTitle,
      subtitle: l10n.phoneSubtitle,
      actions: <Widget>[
        NcPrimaryButton(label: l10n.sendCode, isLoading: _busy, onPressed: _sendCode),
      ],
      children: <Widget>[
        ..._messages(),
        // Un numéro se lit toujours de gauche à droite, même en arabe.
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            key: const ValueKey<String>('phone-field'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.telephoneNumber],
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
              LengthLimitingTextInputFormatter(20),
            ],
            style: Theme.of(context).textTheme.headlineSmall,
            decoration: InputDecoration(hintText: l10n.phoneHint, errorText: _fieldError),
            onSubmitted: (_) => _sendCode(),
          ),
        ),
        const SizedBox(height: NcSpacing.sm),
        Text(l10n.phoneLabel, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: NcSpacing.xs),
        Text(l10n.phoneHelper, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: NcSpacing.lg),
        NcNotice(message: l10n.emergencyNotice, kind: NcNoticeKind.warning),
      ],
    );
  }

  Widget _buildCode(BuildContext context) {
    final l10n = context.l10n;

    return NcPage(
      title: l10n.otpTitle,
      // Le numéro est isolé pour s'afficher de gauche à droite dans une phrase en arabe.
      subtitle: l10n.otpSubtitle(_isolateLtr(_phoneController.text.trim())),
      actions: <Widget>[
        NcPrimaryButton(label: l10n.verify, isLoading: _busy, onPressed: () => _verify(acceptTerms: false)),
        TextButton(
          key: const ValueKey<String>('resend-button'),
          onPressed: _busy || _resendIn > 0 ? null : () => _sendCode(isResend: true),
          child: Text(_resendIn > 0 ? l10n.resendIn(_resendIn) : l10n.resendCode),
        ),
        TextButton(onPressed: _busy ? null : _backToPhone, child: Text(l10n.changeNumber)),
      ],
      children: <Widget>[
        ..._messages(),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            key: const ValueKey<String>('code-field'),
            controller: _codeController,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            textAlign: TextAlign.center,
            autofillHints: const <String>[AutofillHints.oneTimeCode],
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(_codeLength),
            ],
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: 12),
            decoration: InputDecoration(errorText: _fieldError),
            onSubmitted: (_) => _verify(acceptTerms: false),
          ),
        ),
        const SizedBox(height: NcSpacing.sm),
        Text(l10n.otpLabel, style: Theme.of(context).textTheme.labelLarge, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildConsent(BuildContext context) {
    final l10n = context.l10n;
    final allAccepted = _acceptTerms && _acceptPrivacy && (!_isPatientApp || _acceptHealthData);

    return NcPage(
      title: l10n.consentTitle,
      subtitle: l10n.consentIntro,
      actions: <Widget>[
        NcPrimaryButton(
          label: l10n.consentAccept,
          isLoading: _busy,
          onPressed: allAccepted ? () => _verify(acceptTerms: true) : null,
        ),
        TextButton(onPressed: _busy ? null : _backToPhone, child: Text(l10n.cancel)),
      ],
      children: <Widget>[
        ..._messages(),
        _ConsentLine(
          key: const ValueKey<String>('consent-terms'),
          label: l10n.consentTerms,
          value: _acceptTerms,
          onChanged: (value) => setState(() => _acceptTerms = value),
        ),
        _ConsentLine(
          key: const ValueKey<String>('consent-privacy'),
          label: l10n.consentPrivacy,
          value: _acceptPrivacy,
          onChanged: (value) => setState(() => _acceptPrivacy = value),
        ),
        if (_isPatientApp)
          _ConsentLine(
            key: const ValueKey<String>('consent-health'),
            label: l10n.consentHealthData,
            value: _acceptHealthData,
            onChanged: (value) => setState(() => _acceptHealthData = value),
          ),
        const SizedBox(height: NcSpacing.md),
        NcNotice(message: l10n.consentRights),
      ],
    );
  }
}

/// Une case de consentement : rien n'est coché d'avance, l'accord doit être explicite.
class _ConsentLine extends StatelessWidget {
  const _ConsentLine({required this.label, required this.value, required this.onChanged, super.key});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (checked) => onChanged(checked ?? false),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}
