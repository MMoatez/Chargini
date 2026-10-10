import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import nodemailer from 'nodemailer';

export interface VehiculeMailDetails {
  brand: string;
  model: string;
  batteryCapacity: number;
  rangeKm: number;
  connector: string;
  registrationNumber: string;
  isPrimary: boolean;
}

@Injectable()
export class MailService {
  constructor(private readonly configService: ConfigService) {}

  async sendPasswordResetCode(to: string, code: string): Promise<boolean> {
    const host = this.configService.get<string>('SMTP_HOST');
    const user = this.configService.get<string>('SMTP_USER');
    const pass = this.configService.get<string>('SMTP_PASS');

    if (!host || !user || !pass) {
      if (this.configService.get('NODE_ENV') === 'production') {
        throw new ServiceUnavailableException(
          'Le service d’envoi des e-mails est indisponible.',
        );
      }
      console.warn(`[DEV ONLY] Password reset code for ${to}: ${code}`);
      return false;
    }

    const port = Number(this.configService.get('SMTP_PORT') ?? 587);
    const secure = this.configService.get('SMTP_SECURE') === 'true';
    const transporter = nodemailer.createTransport({
      host,
      port,
      secure,
      auth: { user, pass },
    });

    await transporter.sendMail({
      from:
        this.configService.get<string>('SMTP_FROM') ??
        'Chargini <no-reply@chargini.tn>',
      to,
      subject: 'Votre code de réinitialisation Chargini',
      text: `Votre code de vérification Chargini est ${code}. Il expire dans 10 minutes.`,
      html: `
        <div style="font-family:Arial,sans-serif;color:#002c4d">
          <h2>Réinitialisation du mot de passe</h2>
          <p>Votre code de vérification Chargini est :</p>
          <p style="font-size:32px;font-weight:700;letter-spacing:8px;color:#00bf4f">${code}</p>
          <p>Ce code expire dans 10 minutes. Ne le partagez avec personne.</p>
        </div>
      `,
    });
    return true;
  }

  async sendPasswordChangeCode(to: string, code: string): Promise<boolean> {
    const transporter = this.createTransporter();
    if (!transporter) {
      console.warn(`[DEV ONLY] Password change code for ${to}: ${code}`);
      return false;
    }
    await transporter.sendMail({
      from: this.fromAddress,
      to,
      subject: 'Confirmez le changement de votre mot de passe Chargini',
      text: `Votre code de confirmation Chargini est ${code}. Il expire dans 10 minutes.`,
      html: `
        <div style="font-family:Arial,sans-serif;color:#002c4d">
          <h2>Changement du mot de passe</h2>
          <p>Utilisez ce code pour confirmer votre nouveau mot de passe :</p>
          <p style="font-size:32px;font-weight:700;letter-spacing:8px;color:#00bf4f">${code}</p>
          <p>Ce code expire dans 10 minutes. Ne le partagez avec personne.</p>
        </div>
      `,
    });
    return true;
  }

  async sendPasswordChangedNotification(to: string): Promise<void> {
    const transporter = this.createTransporter();
    if (!transporter) {
      console.warn(`[DEV ONLY] Password changed notification for ${to}`);
      return;
    }
    await transporter.sendMail({
      from: this.fromAddress,
      to,
      subject: 'Votre mot de passe Chargini a été modifié',
      text: 'Votre mot de passe Chargini a été modifié avec succès. Si vous n’êtes pas à l’origine de cette action, contactez immédiatement le support.',
      html: `
        <div style="font-family:Arial,sans-serif;color:#002c4d">
          <h2>Mot de passe modifié</h2>
          <p>Votre mot de passe Chargini a été modifié avec succès.</p>
          <p>Si vous n’êtes pas à l’origine de cette action, contactez immédiatement le support Chargini.</p>
        </div>
      `,
    });
  }

  async sendVehiculeAddedNotification(
    to: string,
    firstName: string,
    vehicule: VehiculeMailDetails,
  ): Promise<void> {
    const transporter = this.createTransporter();
    if (!transporter) {
      console.warn(`[DEV ONLY] Vehicule added notification for ${to}`);
      return;
    }
    const name = this.escapeHtml(firstName || 'conducteur');
    const info = await transporter.sendMail({
      from: this.fromAddress,
      to,
      subject: `${vehicule.brand} ${vehicule.model} a rejoint votre profil Chargini`,
      text:
        `Bonjour ${firstName}, votre ${vehicule.brand} ${vehicule.model} ` +
        `(${vehicule.registrationNumber}) a bien été ajouté à votre profil Chargini. ` +
        'Bonne route et excellente expérience avec Chargini !',
      html: this.vehiculeEmailTemplate({
        eyebrow: 'NOUVEAU VÉHICULE',
        title: 'Votre véhicule est prêt !',
        greeting: `Bonjour ${name},`,
        message:
          'Votre véhicule a bien été ajouté à votre profil. Chargini pourra désormais vous proposer les bornes les mieux adaptées.',
        vehicule,
        accent: '#00bf4f',
        footer:
          'Nous vous souhaitons une excellente expérience. Une question ou un problème ? N’hésitez pas à contacter le support Chargini. Bonne route 💚',
      }),
    });
    console.log(
      `[MAIL] Notification d’ajout du véhicule envoyée (${info.messageId}).`,
    );
  }

  async sendVehiculeRemovedNotification(
    to: string,
    firstName: string,
    vehicule: VehiculeMailDetails,
  ): Promise<void> {
    const transporter = this.createTransporter();
    if (!transporter) {
      console.warn(`[DEV ONLY] Vehicule removed notification for ${to}`);
      return;
    }
    const name = this.escapeHtml(firstName || 'conducteur');
    const info = await transporter.sendMail({
      from: this.fromAddress,
      to,
      subject: 'Un véhicule a été retiré de votre compte Chargini',
      text:
        `Bonjour ${firstName}, votre ${vehicule.brand} ${vehicule.model} ` +
        `(${vehicule.registrationNumber}) a été retiré de votre compte Chargini.`,
      html: this.vehiculeEmailTemplate({
        eyebrow: 'VÉHICULE RETIRÉ',
        title: 'Mise à jour de votre garage',
        greeting: `Bonjour ${name},`,
        message:
          'Le véhicule ci-dessous a bien été retiré de votre compte Chargini.',
        vehicule,
        accent: '#e91d43',
        footer:
          'Si vous n’êtes pas à l’origine de cette action, contactez rapidement le support Chargini afin que nous puissions vous aider.',
      }),
    });
    console.log(
      `[MAIL] Notification de retrait du véhicule envoyée (${info.messageId}).`,
    );
  }

  private vehiculeEmailTemplate(options: {
    eyebrow: string;
    title: string;
    greeting: string;
    message: string;
    vehicule: VehiculeMailDetails;
    accent: string;
    footer: string;
  }) {
    const vehicule = options.vehicule;
    const rows = [
      ['Marque', vehicule.brand],
      ['Modèle', vehicule.model],
      ['Batterie', `${vehicule.batteryCapacity} kWh`],
      ['Autonomie', `${vehicule.rangeKm} km`],
      ['Connecteur', vehicule.connector],
      ['Immatriculation', vehicule.registrationNumber],
      ['Statut', vehicule.isPrimary ? 'Véhicule principal' : 'Véhicule secondaire'],
    ]
      .map(
        ([label, value]) => `
          <tr>
            <td style="padding:10px 0;color:#7d89aa;border-bottom:1px solid #e7edf1">${this.escapeHtml(label)}</td>
            <td style="padding:10px 0;text-align:right;font-weight:700;color:#002c4d;border-bottom:1px solid #e7edf1">${this.escapeHtml(value)}</td>
          </tr>`,
      )
      .join('');

    return `
      <!doctype html>
      <html lang="fr">
        <body style="margin:0;background:#f3f7f9;font-family:Arial,sans-serif;color:#002c4d">
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f3f7f9;padding:28px 12px">
            <tr><td align="center">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:600px;background:#fff;border-radius:24px;overflow:hidden;box-shadow:0 12px 36px rgba(0,44,77,.10)">
                <tr><td style="padding:30px;background:linear-gradient(135deg,#003d5b,#006b89);color:#fff">
                  <div style="font-size:26px;font-weight:800">Charg<span style="color:#20d968">ini</span></div>
                  <div style="margin-top:20px;color:${options.accent};font-size:12px;font-weight:800;letter-spacing:2px">${options.eyebrow}</div>
                  <h1 style="margin:8px 0 0;font-size:30px">${options.title}</h1>
                </td></tr>
                <tr><td style="padding:30px">
                  <p style="font-size:18px;font-weight:700;margin-top:0">${options.greeting}</p>
                  <p style="line-height:1.65;color:#596882">${options.message}</p>
                  <div style="margin:24px 0;padding:20px;border:1px solid #dce6eb;border-left:5px solid ${options.accent};border-radius:16px;background:#fbfdfe">
                    <div style="font-size:22px;font-weight:800;margin-bottom:10px">${this.escapeHtml(vehicule.brand)} ${this.escapeHtml(vehicule.model)}</div>
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0">${rows}</table>
                  </div>
                  <p style="line-height:1.65;color:#596882">${options.footer}</p>
                  <p style="margin:28px 0 0;font-weight:700">L’équipe Chargini</p>
                </td></tr>
              </table>
            </td></tr>
          </table>
        </body>
      </html>`;
  }

  private escapeHtml(value: string | number) {
    return String(value)
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#039;');
  }

  private createTransporter() {
    const host = this.configService.get<string>('SMTP_HOST');
    const user = this.configService.get<string>('SMTP_USER');
    const pass = this.configService.get<string>('SMTP_PASS');
    if (!host || !user || !pass) {
      if (this.configService.get('NODE_ENV') === 'production') {
        throw new ServiceUnavailableException(
          'Le service d’envoi des e-mails est indisponible.',
        );
      }
      return null;
    }
    return nodemailer.createTransport({
      host,
      port: Number(this.configService.get('SMTP_PORT') ?? 587),
      secure: this.configService.get('SMTP_SECURE') === 'true',
      auth: { user, pass },
    });
  }

  private get fromAddress() {
    return (
      this.configService.get<string>('SMTP_FROM') ??
      'Chargini <no-reply@chargini.tn>'
    );
  }
}
