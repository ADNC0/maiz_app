require("dotenv").config();
const nodemailer = require("nodemailer");

if (!process.env.EMAIL_USER || !process.env.EMAIL_PASSWORD) {
    throw new Error('EMAIL_USER o EMAIL_PASSWORD no configurados en .env');
}

const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: Number(process.env.EMAIL_PORT || 587),
    secure: String(process.env.EMAIL_SECURE || 'false').toLowerCase() === 'true',
    logger: true,
    debug: true,
    requireTLS: true,
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD
    },
    tls: {
        rejectUnauthorized: false
    }
});

module.exports = async function sendResetEmail(toEmail, token) {
    const appUrl = process.env.APP_URL || 'https://maizapp-ec.com';
    const resetUrl = `${appUrl}/reset-password?token=${encodeURIComponent(token)}`;

    const htmlContent = `
    <div style="font-family: Arial; padding: 20px;">
        <h2 style="color:#2E7D32">🌽 Maiz App – Recuperación de contraseña</h2>
        <p>¡Hola! Hemos recibido una solicitud para restablecer tu contraseña..</p>
        <a href="${resetUrl}" 
           style="display:inline-block; background:#2E7D32; padding:12px 20px; 
                  text-decoration:none; color:#fff; border-radius:8px;">
           Restablecer contraseña
        </a>
        <p>Este enlace expirará en <strong>15 minutos</strong>.</p>
        <p>Si no solicitaste este cambio, simplemente ignora este mensaje.</p>
        <hr>
        <p>Soporte: soporte@maizapp.com</p>
    </div>
    `;

    await transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: toEmail,
        subject: "Recuperación de contraseña – Maiz App",
        html: htmlContent
    });
};
