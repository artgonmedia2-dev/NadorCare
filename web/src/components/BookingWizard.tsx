'use client';

import Link from 'next/link';
import { useCallback, useEffect, useId, useRef, useState, type FormEvent, type ReactNode } from 'react';

import type { Locale } from '@/i18n/config';
import { fill, isolateLtr, type Dictionary } from '@/i18n/dictionary';
import { ApiFailure, call } from '@/lib/client-api';
import { formatDirhams, longDate, slotTime, todayInNador } from '@/lib/format';
import type {
  AppUser,
  Booking,
  BookingDay,
  CareService,
  PatientAddress,
  PatientProfile,
  PriceQuote,
} from '@/lib/types';

import { CheckIcon, InfoIcon, WarningIcon } from './icons';

type Step = 'loading' | 'phone' | 'code' | 'consent' | 'patient' | 'address' | 'slot' | 'summary' | 'done';

const ASAP = 'asap';
const RELATIONSHIPS = ['self', 'parent', 'child', 'spouse', 'other'] as const;
/** Étapes numérotées du parcours, une fois connecté : les mêmes que dans l'application. */
const NUMBERED: Partial<Record<Step, number>> = { patient: 1, address: 2, slot: 3, summary: 4 };

type Props = { locale: Locale; t: Dictionary; service: CareService };

export function BookingWizard({ locale, t, service }: Props) {
  const [step, setStep] = useState<Step>('loading');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  // Connexion
  const [user, setUser] = useState<AppUser | null>(null);
  const [phone, setPhone] = useState('');
  const [code, setCode] = useState('');
  const [resendIn, setResendIn] = useState(0);
  const [consents, setConsents] = useState({ terms: false, privacy: false, health: false });

  // Réservation
  const [profiles, setProfiles] = useState<PatientProfile[] | null>(null);
  const [addresses, setAddresses] = useState<PatientAddress[] | null>(null);
  const [profileId, setProfileId] = useState<string | null>(null);
  const [addressId, setAddressId] = useState<string | null>(null);
  const [addingProfile, setAddingProfile] = useState(false);
  const [addingAddress, setAddingAddress] = useState(false);
  // L'API exige la position GPS de toute nouvelle adresse, comme dans l'application.
  const [position, setPosition] = useState<{ latitude: number; longitude: number } | null>(null);
  const [locating, setLocating] = useState(false);
  const [day, setDay] = useState(() => todayInNador());
  const [dayData, setDayData] = useState<BookingDay | null>(null);
  const [slotChoice, setSlotChoice] = useState<string | null>(null);
  const [quote, setQuote] = useState<PriceQuote | null>(null);
  const [note, setNote] = useState('');
  const [prescriptionId, setPrescriptionId] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  const [created, setCreated] = useState<Booking | null>(null);

  const heading = useRef<HTMLHeadingElement>(null);

  const message = useCallback(
    (failure: unknown): string => {
      if (failure instanceof ApiFailure) {
        if (failure.code === 'network') {
          return t.errorNetwork;
        }
        return failure.message || t.errorUnknown;
      }
      return t.errorUnknown;
    },
    [t],
  );

  const go = useCallback((next: Step) => {
    setError(null);
    setFieldErrors({});
    setStep(next);
  }, []);

  // À chaque écran, le titre reçoit le focus : les lecteurs d'écran annoncent le changement.
  useEffect(() => {
    if (step !== 'loading') {
      heading.current?.focus();
    }
  }, [step, addingProfile, addingAddress]);

  /** Une session expirée renvoie à la connexion, sans perdre le soin choisi. */
  const guard = useCallback(
    (failure: unknown): boolean => {
      if (failure instanceof ApiFailure && failure.detail.status === 401) {
        setUser(null);
        go('phone');
        return true;
      }
      return false;
    },
    [go],
  );

  const loadAccount = useCallback(async () => {
    try {
      const [profileList, addressList] = await Promise.all([
        call<{ data: PatientProfile[] }>(locale, '/api/account/patient-profiles'),
        call<{ data: PatientAddress[] }>(locale, '/api/account/addresses'),
      ]);
      setProfiles(profileList.data);
      setAddresses(addressList.data);
      // Un seul patient ou une seule adresse desservie : inutile de faire choisir.
      if (profileList.data.length === 1) {
        setProfileId(profileList.data[0]?.id ?? null);
      }
      const covered = addressList.data.filter((address) => address.is_covered);
      if (covered.length === 1) {
        setAddressId(covered[0]?.id ?? null);
      }
      go('patient');
    } catch (failure) {
      if (!guard(failure)) {
        setError(message(failure));
        setStep('patient');
      }
    }
  }, [go, guard, locale, message]);

  // Au chargement : quelqu'un est-il déjà connecté ?
  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const session = await call<{ user: AppUser | null }>(locale, '/api/auth/session');
        if (cancelled) {
          return;
        }
        if (session.user) {
          setUser(session.user);
          await loadAccount();
        } else {
          setStep('phone');
        }
      } catch {
        if (!cancelled) {
          setStep('phone');
        }
      }
    })();
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Compte à rebours avant de pouvoir redemander un code.
  useEffect(() => {
    if (resendIn <= 0) {
      return;
    }
    const timer = setTimeout(() => setResendIn((value) => value - 1), 1000);
    return () => clearTimeout(timer);
  }, [resendIn]);

  // --- Connexion ---

  async function requestCode() {
    if (phone.replace(/\D/g, '').length < 8) {
      setFieldErrors({ phone: t.phoneInvalid });
      return;
    }
    setBusy(true);
    setError(null);
    setFieldErrors({});
    try {
      const challenge = await call<{ resend_in?: number }>(locale, '/api/auth/otp/request', {
        method: 'POST',
        json: { phone: phone.trim() },
      });
      setCode('');
      setResendIn(challenge.resend_in ?? 60);
      go('code');
    } catch (failure) {
      if (failure instanceof ApiFailure && failure.code === 'otp_too_soon') {
        // Un code vient d'être envoyé : on passe à sa saisie.
        setResendIn(failure.detail.retry_after ?? 60);
        go('code');
      } else if (failure instanceof ApiFailure && failure.firstErrorFor('phone')) {
        setFieldErrors({ phone: failure.firstErrorFor('phone') ?? '' });
      } else {
        setError(message(failure));
      }
    } finally {
      setBusy(false);
    }
  }

  async function verifyCode(acceptTerms: boolean) {
    if (code.length !== 6) {
      go('code');
      setFieldErrors({ code: t.otpIncomplete });
      return;
    }
    setBusy(true);
    setError(null);
    setFieldErrors({});
    try {
      const session = await call<{ user: AppUser }>(locale, '/api/auth/otp/verify', {
        method: 'POST',
        json: { phone: phone.trim(), code, accept_terms: acceptTerms },
      });
      setUser(session.user);
      await loadAccount();
    } catch (failure) {
      if (failure instanceof ApiFailure && failure.code === 'consent_required' && !acceptTerms) {
        // Numéro inconnu : le code reste valable, on demande le consentement.
        go('consent');
      } else {
        setStep('code');
        setError(message(failure));
      }
    } finally {
      setBusy(false);
    }
  }

  async function logout() {
    setBusy(true);
    try {
      await call(locale, '/api/auth/session', { method: 'DELETE' });
    } catch {
      // Hors ligne : le cookie sera effacé à la prochaine tentative.
    }
    setUser(null);
    setProfiles(null);
    setAddresses(null);
    setProfileId(null);
    setAddressId(null);
    setBusy(false);
    go('phone');
  }

  // --- Patient et adresse ---

  async function createProfile(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const draft = {
      relationship: String(form.get('relationship') ?? ''),
      first_name: String(form.get('first_name') ?? '').trim(),
      last_name: String(form.get('last_name') ?? '').trim(),
    };
    const errors: Record<string, string> = {};
    if (!draft.relationship) errors.relationship = t.fieldRequired;
    if (draft.first_name.length < 2) errors.first_name = t.fieldRequired;
    if (draft.last_name.length < 2) errors.last_name = t.fieldRequired;
    if (Object.keys(errors).length > 0) {
      setFieldErrors(errors);
      return;
    }

    setBusy(true);
    setError(null);
    setFieldErrors({});
    try {
      const saved = await call<{ data: PatientProfile }>(locale, '/api/account/patient-profiles', {
        method: 'POST',
        json: draft,
      });
      setProfiles((list) => [...(list ?? []), saved.data]);
      setProfileId(saved.data.id);
      setAddingProfile(false);
    } catch (failure) {
      if (!guard(failure)) {
        applyFieldErrors(failure, ['relationship', 'first_name', 'last_name']);
      }
    } finally {
      setBusy(false);
    }
  }

  function locate() {
    if (!('geolocation' in navigator)) {
      setFieldErrors((errors) => ({ ...errors, position: t.locationUnavailable }));
      return;
    }
    setLocating(true);
    setFieldErrors((errors) => ({ ...errors, position: '' }));
    navigator.geolocation.getCurrentPosition(
      (found) => {
        setPosition({ latitude: found.coords.latitude, longitude: found.coords.longitude });
        setLocating(false);
      },
      (failure) => {
        setLocating(false);
        setFieldErrors((errors) => ({
          ...errors,
          position: failure.code === failure.PERMISSION_DENIED ? t.locationDeniedWeb : t.locationUnavailable,
        }));
      },
      { enableHighAccuracy: true, timeout: 20_000 },
    );
  }

  async function createAddress(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const draft = {
      label: String(form.get('label') ?? '').trim(),
      line: String(form.get('line') ?? '').trim(),
      access_notes: String(form.get('access_notes') ?? '').trim() || null,
      latitude: position?.latitude ?? null,
      longitude: position?.longitude ?? null,
    };
    const errors: Record<string, string> = {};
    if (draft.label.length < 2) errors.label = t.fieldRequired;
    if (draft.line.length < 3) errors.line = t.fieldRequired;
    if (!position) errors.position = t.locationMissing;
    if (Object.keys(errors).length > 0) {
      setFieldErrors(errors);
      return;
    }

    setBusy(true);
    setError(null);
    setFieldErrors({});
    try {
      const saved = await call<{ data: PatientAddress }>(locale, '/api/account/addresses', {
        method: 'POST',
        json: draft,
      });
      setAddresses((list) => [...(list ?? []), saved.data]);
      if (saved.data.is_covered) {
        setAddressId(saved.data.id);
      }
      setAddingAddress(false);
      setPosition(null);
    } catch (failure) {
      if (!guard(failure)) {
        applyFieldErrors(failure, ['label', 'line', 'access_notes']);
      }
    } finally {
      setBusy(false);
    }
  }

  /** Place les erreurs du serveur sous leur champ ; ce qui ne correspond à aucun champ va en haut. */
  function applyFieldErrors(failure: unknown, fields: string[]) {
    const found: Record<string, string> = {};
    if (failure instanceof ApiFailure) {
      for (const field of fields) {
        const text = failure.firstErrorFor(field);
        if (text) {
          found[field] = text;
        }
      }
    }
    setFieldErrors(found);
    if (Object.keys(found).length === 0) {
      setError(message(failure));
    }
  }

  // --- Créneau ---

  useEffect(() => {
    if (step !== 'slot') {
      return;
    }
    let cancelled = false;
    setDayData(null);
    (async () => {
      try {
        const result = await call<{ data: BookingDay }>(
          locale,
          `/api/account/bookings/slots?service_id=${encodeURIComponent(service.id)}&date=${day}`,
        );
        if (!cancelled) {
          setDayData(result.data);
        }
      } catch (failure) {
        if (!cancelled && !guard(failure)) {
          setError(message(failure));
          setDayData({ slots: [], immediate_available: false });
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [step, day, service.id, locale, guard, message]);

  // --- Récapitulatif ---

  useEffect(() => {
    if (step !== 'summary') {
      return;
    }
    let cancelled = false;
    setQuote(null);
    (async () => {
      try {
        const result = await call<{ data: PriceQuote }>(locale, '/api/account/bookings/quote', {
          method: 'POST',
          json: { service_id: service.id, ...(slotChoice && slotChoice !== ASAP ? { scheduled_at: slotChoice } : {}) },
        });
        if (!cancelled) {
          setQuote(result.data);
        }
      } catch (failure) {
        if (!cancelled && !guard(failure)) {
          setError(message(failure));
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [step, slotChoice, service.id, locale, guard, message]);

  async function uploadPrescription(file: File | undefined) {
    if (!file) {
      return;
    }
    setUploading(true);
    setError(null);
    try {
      const form = new FormData();
      form.append('file', file);
      const result = await call<{ data: { id: string } }>(locale, '/api/account/files/prescriptions', {
        method: 'POST',
        form,
      });
      setPrescriptionId(result.data.id);
    } catch (failure) {
      if (!guard(failure)) {
        setError(failure instanceof ApiFailure ? (failure.firstErrorFor('file') ?? message(failure)) : message(failure));
      }
    } finally {
      setUploading(false);
    }
  }

  async function send() {
    if (service.requires_prescription && !prescriptionId) {
      setError(t.prescriptionMissing);
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const immediate = slotChoice === ASAP;
      const result = await call<{ data: Booking }>(locale, '/api/account/bookings', {
        method: 'POST',
        json: {
          service_id: service.id,
          patient_profile_id: profileId,
          address_id: addressId,
          type: immediate ? 'immediate' : 'scheduled',
          scheduled_at: immediate ? null : slotChoice,
          payment_method: 'cash',
          patient_note: note.trim() || null,
          prescription_file_id: prescriptionId,
        },
      });
      setCreated(result.data);
      go('done');
    } catch (failure) {
      if (!guard(failure)) {
        setError(message(failure));
      }
    } finally {
      setBusy(false);
    }
  }

  // --- Affichage ---

  const numbered = NUMBERED[step];
  const profile = profiles?.find((item) => item.id === profileId) ?? null;
  const address = addresses?.find((item) => item.id === addressId) ?? null;
  const money = (centimes: number) => formatDirhams(centimes, locale, t.currencyUnit);

  function title(text: string): ReactNode {
    return (
      <h1 ref={heading} tabIndex={-1} style={{ outline: 'none' }}>
        {text}
      </h1>
    );
  }

  const errorNotice = error && (
    <div className="notice notice-error" role="alert">
      <InfoIcon />
      <p>{error}</p>
    </div>
  );

  // Les quatre étapes, avec leur nom : on voit d'où l'on vient et ce qui reste.
  const stepNames = [t.summaryPatient, t.summaryAddress, t.summarySlot, t.stepCheck];
  const progress = numbered && (
    <div>
      <p className="progress">{fill(t.stepProgress, { current: numbered, total: 4 })}</p>
      <ol className="stepper" aria-hidden="true">
        {stepNames.map((name, index) => (
          <li
            key={name}
            className={index + 1 < numbered ? 'is-done' : index + 1 === numbered ? 'is-current' : undefined}
          >
            <span className="stepper-dot">{index + 1 < numbered ? <CheckIcon size={16} /> : index + 1}</span>
            <span className="stepper-name">{name}</span>
          </li>
        ))}
      </ol>
    </div>
  );

  if (step === 'loading') {
    return (
      <p className="muted" role="status" style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
        <span className="spinner" aria-hidden="true" />
        {t.loading}
      </p>
    );
  }

  if (step === 'phone') {
    return (
      <form
        className="stack"
        noValidate
        onSubmit={(event) => {
          event.preventDefault();
          void requestCode();
        }}
      >
        {title(t.phoneTitle)}
        <p className="muted">{t.phoneSubtitle}</p>
        {errorNotice}
        <Field id="phone" label={t.phoneLabel} error={fieldErrors.phone} help={t.phoneHelper}>
          {(props) => (
            <input
              {...props}
              className="ltr"
              type="tel"
              inputMode="tel"
              autoComplete="tel"
              placeholder={t.phoneHint}
              maxLength={20}
              value={phone}
              onChange={(event) => setPhone(event.target.value.replace(/[^0-9+ ]/g, ''))}
            />
          )}
        </Field>
        <div className="actions">
          <SubmitButton busy={busy} label={t.sendCode} />
        </div>
      </form>
    );
  }

  if (step === 'code') {
    return (
      <form
        className="stack"
        noValidate
        onSubmit={(event) => {
          event.preventDefault();
          void verifyCode(false);
        }}
      >
        {title(t.otpTitle)}
        <p className="muted">{fill(t.otpSubtitle, { phone: isolateLtr(phone.trim()) })}</p>
        {errorNotice}
        <Field id="code" label={t.otpLabel} error={fieldErrors.code}>
          {(props) => (
            <input
              {...props}
              className="ltr code-input"
              type="text"
              inputMode="numeric"
              autoComplete="one-time-code"
              maxLength={6}
              autoFocus
              value={code}
              onChange={(event) => setCode(event.target.value.replace(/\D/g, '').slice(0, 6))}
            />
          )}
        </Field>
        <div className="actions">
          <SubmitButton busy={busy} label={t.verify} />
          <button
            type="button"
            className="button button-text"
            disabled={busy || resendIn > 0}
            onClick={() => void requestCode()}
          >
            {resendIn > 0 ? fill(t.resendIn, { seconds: resendIn }) : t.resendCode}
          </button>
          <button type="button" className="button button-text" disabled={busy} onClick={() => go('phone')}>
            {t.changeNumber}
          </button>
        </div>
      </form>
    );
  }

  if (step === 'consent') {
    const all = consents.terms && consents.privacy && consents.health;
    return (
      <form
        className="stack"
        noValidate
        onSubmit={(event) => {
          event.preventDefault();
          if (all) {
            void verifyCode(true);
          }
        }}
      >
        {title(t.consentTitle)}
        <p className="muted">{t.consentIntro}</p>
        {errorNotice}
        {/* Rien n'est coché d'avance : l'accord doit être explicite. */}
        <fieldset>
          {(
            [
              ['terms', t.consentTerms],
              ['privacy', t.consentPrivacy],
              ['health', t.consentHealthData],
            ] as const
          ).map(([key, label]) => (
            <label key={key} className="choice">
              <input
                type="checkbox"
                checked={consents[key]}
                onChange={(event) => setConsents((value) => ({ ...value, [key]: event.target.checked }))}
              />
              <span>{label}</span>
            </label>
          ))}
        </fieldset>
        <div className="actions">
          <SubmitButton busy={busy} label={t.consentAccept} disabled={!all} />
          <button type="button" className="button button-text" disabled={busy} onClick={() => go('phone')}>
            {t.cancel}
          </button>
        </div>
      </form>
    );
  }

  if (step === 'patient') {
    const list = profiles ?? [];
    const showForm = addingProfile || list.length === 0;

    return (
      <div className="stack">
        {title(t.bookingStepPatientTitle)}
        {progress}
        {errorNotice}

        {showForm ? (
          <form className="stack" noValidate onSubmit={(event) => void createProfile(event)}>
            {list.length === 0 && <p className="muted">{t.bookingNoProfile}</p>}
            <fieldset>
              <legend className="legend">{t.relationshipLabel}</legend>
              {RELATIONSHIPS.map((value) => (
                <label key={value} className="choice">
                  <input type="radio" name="relationship" value={value} />
                  <span>{relationshipLabel(t, value)}</span>
                </label>
              ))}
              {fieldErrors.relationship && <p className="field-error">{fieldErrors.relationship}</p>}
            </fieldset>
            <Field id="first_name" label={t.firstNameLabel} error={fieldErrors.first_name}>
              {(props) => <input {...props} name="first_name" autoComplete="given-name" maxLength={100} />}
            </Field>
            <Field id="last_name" label={t.lastNameLabel} error={fieldErrors.last_name}>
              {(props) => <input {...props} name="last_name" autoComplete="family-name" maxLength={100} />}
            </Field>
            <div className="actions">
              <SubmitButton busy={busy} label={t.save} />
              {list.length > 0 && (
                <button type="button" className="button button-text" onClick={() => setAddingProfile(false)}>
                  {t.cancel}
                </button>
              )}
            </div>
          </form>
        ) : (
          <>
            <fieldset>
              <legend className="legend">{t.summaryPatient}</legend>
              {list.map((item) => (
                <label key={item.id} className="choice">
                  <input
                    type="radio"
                    name="profile"
                    checked={profileId === item.id}
                    onChange={() => {
                      setProfileId(item.id);
                      setError(null);
                    }}
                  />
                  <span>
                    {item.first_name} {item.last_name}
                    <small>{relationshipLabel(t, item.relationship)}</small>
                  </span>
                </label>
              ))}
            </fieldset>
            <div className="actions">
              <button
                type="button"
                className="button button-primary"
                onClick={() => (profileId ? go('address') : setError(t.bookingChoosePatient))}
              >
                {t.continueButton}
              </button>
              <button type="button" className="button button-secondary" onClick={() => setAddingProfile(true)}>
                {t.profileAdd}
              </button>
            </div>
          </>
        )}

        {user && (
          <p className="muted">
            {fill(t.signedInAs, { phone: isolateLtr(user.phone) })}{' '}
            <button type="button" className="button button-text" disabled={busy} onClick={() => void logout()}>
              {t.logout}
            </button>
          </p>
        )}
      </div>
    );
  }

  if (step === 'address') {
    const list = addresses ?? [];
    const showForm = addingAddress || list.length === 0;

    return (
      <div className="stack">
        {title(t.bookingStepAddressTitle)}
        {progress}
        {errorNotice}

        {showForm ? (
          <form className="stack" noValidate onSubmit={(event) => void createAddress(event)}>
            {list.length === 0 && <p className="muted">{t.bookingNoAddress}</p>}
            <Field id="label" label={t.addressLabelLabel} error={fieldErrors.label} help={t.addressLabelHint}>
              {(props) => <input {...props} name="label" maxLength={60} />}
            </Field>
            <Field id="line" label={t.addressLineLabel} error={fieldErrors.line} help={t.addressLineHint}>
              {(props) => <input {...props} name="line" autoComplete="street-address" maxLength={255} />}
            </Field>
            <Field
              id="access_notes"
              label={t.accessNotesLabel}
              error={fieldErrors.access_notes}
              help={t.accessNotesHint}
            >
              {(props) => <textarea {...props} name="access_notes" maxLength={500} />}
            </Field>
            <div className="field">
              <p className="legend">{t.locationLabel}</p>
              <p className="field-help" style={{ marginTop: 0, marginBottom: '0.6rem' }}>
                {t.locationHelp}
              </p>
              {position && (
                <div className="notice" role="status" style={{ marginBottom: '0.6rem' }}>
                  <CheckIcon />
                  <p>{t.locationSet}</p>
                </div>
              )}
              <button type="button" className="button button-secondary button-block" disabled={locating} onClick={locate}>
                {locating && <span className="spinner" aria-hidden="true" />}
                {t.locationUse}
              </button>
              {fieldErrors.position && (
                <p className="field-error" role="alert">
                  {fieldErrors.position}
                </p>
              )}
            </div>
            <div className="actions">
              <SubmitButton busy={busy} label={t.save} />
              <button
                type="button"
                className="button button-text"
                onClick={() => (list.length > 0 ? setAddingAddress(false) : go('patient'))}
              >
                {list.length > 0 ? t.cancel : t.back}
              </button>
            </div>
          </form>
        ) : (
          <>
            <fieldset>
              <legend className="legend">{t.summaryAddress}</legend>
              {list.map((item) => (
                <label key={item.id} className="choice">
                  <input
                    type="radio"
                    name="address"
                    checked={addressId === item.id}
                    onChange={() => {
                      setAddressId(item.id);
                      setError(null);
                    }}
                  />
                  <span>
                    {item.label}
                    <small>{item.line}</small>
                    {!item.is_covered && <small>{t.addressNotCovered}</small>}
                  </span>
                </label>
              ))}
            </fieldset>
            <div className="actions">
              <button
                type="button"
                className="button button-primary"
                onClick={() => {
                  if (!address) {
                    setError(t.bookingChooseAddress);
                  } else if (!address.is_covered) {
                    setError(t.bookingAddressNotCovered);
                  } else {
                    go('slot');
                  }
                }}
              >
                {t.continueButton}
              </button>
              <button type="button" className="button button-secondary" onClick={() => setAddingAddress(true)}>
                {t.addressAdd}
              </button>
              <button type="button" className="button button-text" onClick={() => go('patient')}>
                {t.back}
              </button>
            </div>
          </>
        )}
      </div>
    );
  }

  if (step === 'slot') {
    const isToday = day === todayInNador();
    const hasChoices = dayData !== null && (dayData.slots.length > 0 || (isToday && dayData.immediate_available));

    return (
      <div className="stack">
        {title(t.bookingStepSlotTitle)}
        <p className="muted">{t.slotNadorTime}</p>
        {progress}
        {errorNotice}

        <Field id="day" label={t.dayLabel} help={longDate(day, locale)}>
          {(props) => (
            <input
              {...props}
              type="date"
              value={day}
              min={todayInNador()}
              max={todayInNador(30)}
              onChange={(event) => {
                if (event.target.value) {
                  setDay(event.target.value);
                  setSlotChoice(null);
                  setError(null);
                }
              }}
            />
          )}
        </Field>

        {dayData === null ? (
          <p className="muted" role="status" style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
            <span className="spinner" aria-hidden="true" />
            {t.loading}
          </p>
        ) : !hasChoices ? (
          <div className="notice" role="status">
            <InfoIcon />
            <p>{t.slotNone}</p>
          </div>
        ) : (
          <fieldset>
            <legend className="legend">{t.summarySlot}</legend>
            {isToday && dayData.immediate_available && (
              <label className="choice" style={{ marginBottom: '0.5rem' }}>
                <input
                  type="radio"
                  name="slot"
                  checked={slotChoice === ASAP}
                  onChange={() => {
                    setSlotChoice(ASAP);
                    setError(null);
                  }}
                />
                <span>{t.slotAsap}</span>
              </label>
            )}
            <div className="slot-grid">
              {dayData.slots.map((slot) => (
                <label key={slot} className="choice">
                  <input
                    type="radio"
                    name="slot"
                    checked={slotChoice === slot}
                    onChange={() => {
                      setSlotChoice(slot);
                      setError(null);
                    }}
                  />
                  <span className="ltr">{slotTime(slot)}</span>
                </label>
              ))}
            </div>
          </fieldset>
        )}

        <div className="actions">
          <button
            type="button"
            className="button button-primary"
            onClick={() => (slotChoice ? go('summary') : setError(t.slotChoose))}
          >
            {t.continueButton}
          </button>
          <button type="button" className="button button-text" onClick={() => go('address')}>
            {t.back}
          </button>
        </div>
      </div>
    );
  }

  if (step === 'summary') {
    return (
      <div className="stack">
        {title(t.bookingStepSummaryTitle)}
        {progress}
        {errorNotice}

        <dl className="card summary">
          <div>
            <dt>{t.summaryService}</dt>
            <dd>{service.name}</dd>
          </div>
          <div>
            <dt>{t.summaryPatient}</dt>
            <dd>{profile ? `${profile.first_name} ${profile.last_name}` : ''}</dd>
          </div>
          <div>
            <dt>{t.summaryAddress}</dt>
            <dd>{address ? `${address.label}\n${address.line}` : ''}</dd>
          </div>
          <div>
            <dt>{t.summarySlot}</dt>
            <dd>
              {slotChoice === ASAP || !slotChoice
                ? t.slotAsap
                : fill(t.dateAtTime, { date: longDate(day, locale), time: isolateLtr(slotTime(slotChoice)) })}
            </dd>
          </div>
          <div>
            <dt>{t.summaryPayment}</dt>
            <dd>{t.paymentCash}</dd>
          </div>
        </dl>

        <div className="card" aria-live="polite">
          {quote === null ? (
            <p className="muted">{t.loading}</p>
          ) : (
            <>
              <p className="price-line">
                <span>{t.summaryBasePrice}</span>
                <span className="ltr">{money(quote.base)}</span>
              </p>
              {quote.surcharges.map((line) => (
                <p key={line.label} className="price-line">
                  <span>{line.label}</span>
                  <span className="ltr">+ {money(line.amount)}</span>
                </p>
              ))}
              <p className="price-line price-total">
                <span>{t.summaryTotal}</span>
                <span className="ltr">{money(quote.total)}</span>
              </p>
            </>
          )}
        </div>

        {service.requires_prescription && (
          <div className="stack">
            <h2>{t.servicePrescriptionRequired}</h2>
            {prescriptionId ? (
              <div className="notice" role="status">
                <CheckIcon />
                <p>{t.prescriptionAdded}</p>
              </div>
            ) : uploading ? (
              <p className="muted" role="status">
                {t.prescriptionSending}
              </p>
            ) : (
              <Field id="prescription" label={t.prescriptionUpload} help={t.servicePrescriptionHelp}>
                {(props) => (
                  <input
                    {...props}
                    type="file"
                    accept="image/*,application/pdf"
                    onChange={(event) => void uploadPrescription(event.target.files?.[0])}
                  />
                )}
              </Field>
            )}
          </div>
        )}

        <Field id="note" label={t.noteLabel} help={t.noteHint}>
          {(props) => (
            <textarea {...props} maxLength={1000} value={note} onChange={(event) => setNote(event.target.value)} />
          )}
        </Field>

        <div className="actions">
          <button
            type="button"
            className="button button-primary"
            disabled={busy || uploading}
            onClick={() => void send()}
          >
            {busy && <span className="spinner" aria-hidden="true" />}
            {t.bookingConfirm}
          </button>
          <button type="button" className="button button-text" disabled={busy} onClick={() => go('slot')}>
            {t.back}
          </button>
        </div>
      </div>
    );
  }

  // Confirmation
  return (
    <div className="stack">
      <div className="success-mark">
        <CheckIcon size={56} />
      </div>
      {title(t.bookingSentTitle)}
      <p>{fill(t.bookingSentBody, { reference: isolateLtr(created?.reference ?? '') })}</p>
      <div className="notice" role="status">
        <InfoIcon />
        <p>{t.statusPending}</p>
      </div>
      <p className="muted">{t.followInApp}</p>
      <div className="notice notice-warning" role="note">
        <WarningIcon />
        <p>{t.emergencyNotice}</p>
      </div>
      <div className="actions">
        <Link className="button button-secondary" href={`/${locale}/soins`}>
          {t.bookAnother}
        </Link>
      </div>
    </div>
  );
}

function relationshipLabel(t: Dictionary, value: (typeof RELATIONSHIPS)[number]): string {
  return {
    self: t.relationshipSelf,
    parent: t.relationshipParent,
    child: t.relationshipChild,
    spouse: t.relationshipSpouse,
    other: t.relationshipOther,
  }[value];
}

/** Champ avec son libellé au-dessus, son aide et son erreur, reliés pour les lecteurs d'écran. */
function Field({
  id,
  label,
  error,
  help,
  children,
}: {
  id: string;
  label: string;
  error?: string;
  help?: string;
  children: (props: { id: string; 'aria-invalid': boolean; 'aria-describedby': string | undefined }) => ReactNode;
}) {
  const unique = useId();
  const fieldId = `${id}-${unique}`;
  const describedBy = [error ? `${fieldId}-error` : null, help ? `${fieldId}-help` : null].filter(Boolean).join(' ');

  return (
    <div className="field">
      <label htmlFor={fieldId}>{label}</label>
      {children({ id: fieldId, 'aria-invalid': Boolean(error), 'aria-describedby': describedBy || undefined })}
      {error && (
        <p id={`${fieldId}-error`} className="field-error" role="alert">
          {error}
        </p>
      )}
      {help && (
        <p id={`${fieldId}-help`} className="field-help">
          {help}
        </p>
      )}
    </div>
  );
}

function SubmitButton({ busy, label, disabled = false }: { busy: boolean; label: string; disabled?: boolean }) {
  return (
    <button type="submit" className="button button-primary" disabled={busy || disabled}>
      {busy && <span className="spinner" aria-hidden="true" />}
      {label}
    </button>
  );
}
