// Construit les dictionnaires du site : les textes communs viennent des fichiers ARB de
// l'application mobile (une seule formulation pour les deux), les textes propres au site
// de src/i18n/web-texts.json. À relancer après toute modification : `pnpm texts`.
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const arbDir = join(root, '..', 'mobile', 'packages', 'nc_l10n', 'lib', 'src', 'arb');
const outDir = join(root, 'src', 'i18n', 'generated');

const sharedKeys = [
  'emergencyNotice', 'phoneTitle', 'phoneSubtitle', 'phoneLabel', 'phoneHint', 'phoneHelper', 'sendCode',
  'phoneInvalid', 'otpTitle', 'otpSubtitle', 'otpLabel', 'verify', 'resendCode', 'resendIn', 'changeNumber',
  'otpIncomplete', 'consentTitle', 'consentIntro', 'consentTerms', 'consentPrivacy', 'consentHealthData',
  'consentAccept', 'cancel', 'continueButton', 'retry', 'save', 'bookService', 'bookingStepPatientTitle',
  'bookingStepAddressTitle', 'bookingStepSlotTitle', 'bookingStepSummaryTitle', 'bookingNoProfile',
  'bookingNoAddress', 'bookingChoosePatient', 'bookingChooseAddress', 'bookingAddressNotCovered', 'profileAdd',
  'addressAdd', 'relationshipLabel', 'relationshipSelf', 'relationshipParent', 'relationshipChild',
  'relationshipSpouse', 'relationshipOther', 'firstNameLabel', 'lastNameLabel', 'addressLabelLabel',
  'addressLabelHint', 'addressLineLabel', 'addressLineHint', 'accessNotesLabel', 'accessNotesHint',
  'addressNotCovered', 'slotNadorTime', 'slotChoose', 'slotNone', 'slotAsap', 'summaryService', 'summaryPatient',
  'summaryAddress', 'summarySlot', 'summaryPayment', 'paymentCash', 'summaryBasePrice', 'summaryTotal',
  'noteLabel', 'noteHint', 'servicePrescriptionRequired', 'servicePrescriptionHelp', 'prescriptionAdded',
  'prescriptionMissing', 'bookingConfirm', 'bookingSentTitle', 'bookingSentBody', 'statusPending',
  'serviceDuration', 'serviceDurationLabel', 'servicePriceLabel', 'servicePriceNote', 'serviceProvidedBy',
  'stepProgress', 'dateAtTime', 'homeCatalogue', 'catalogueEmpty', 'logout', 'homePatientIntro',
  'locationUse', 'locationSet', 'locationLabel', 'locationHelp', 'locationMissing', 'locationUnavailable',
  'fieldRequired', 'catalogueSearchHint', 'catalogueNoResult',
  'teleconsultationLabel', 'teleconsultationServiceNote',
];

const web = JSON.parse(readFileSync(join(root, 'src', 'i18n', 'web-texts.json'), 'utf8'));
const webKeys = Object.keys(web.fr);

mkdirSync(outDir, { recursive: true });

for (const locale of ['fr', 'ar', 'en']) {
  const arb = JSON.parse(readFileSync(join(arbDir, `app_${locale}.arb`), 'utf8'));
  const out = {};

  for (const key of sharedKeys) {
    if (typeof arb[key] !== 'string') {
      throw new Error(`Texte « ${key} » absent de app_${locale}.arb`);
    }
    out[key] = arb[key];
  }
  for (const key of webKeys) {
    if (typeof web[locale]?.[key] !== 'string') {
      throw new Error(`Texte « ${key} » absent de web-texts.json pour « ${locale} »`);
    }
    out[key] = web[locale][key];
  }

  writeFileSync(join(outDir, `${locale}.json`), `${JSON.stringify(out, null, 2)}\n`);
}

console.log(`Dictionnaires écrits : ${sharedKeys.length} textes communs, ${webKeys.length} propres au site.`);
