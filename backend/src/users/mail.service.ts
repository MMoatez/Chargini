import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import nodemailer from 'nodemailer';

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
}
