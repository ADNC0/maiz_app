// maiz_backend_node/parcelRoutes.js
const express = require("express");
const router = express.Router();
const db = require("./db");

/**
 * Acepta ambos nombres de campos para compatibilidad con tu app actual:
 * name | variety
 * latitude | lat
 * longitude | lng
 */

// Crear cultivo/parcela
router.post("/api/crops", async (req, res) => {
  try {
    console.log('POST /api/crops body:', req.body, 'caller', req.user && req.user.id);
    const {
      user_id,
      name,
      variety,
      latitude,
      lat,
      longitude,
      lng,
      area_ha,
      location_desc,
      sow_date,
      notes,
    } = req.body;

    const callerId = req.user.id;
    // Si es admin, puede crear en nombre de otro usuario
    const targetUser = (req.user.role === 'Admin' || req.user.role === 'Administrador') ? (user_id || callerId) : callerId;

    const v = variety || name;          // compatibilidad: si viene "name", lo usamos como variedad
    const la = lat ?? latitude;
    const ln = lng ?? longitude;

    if (!targetUser || !v || la == null || ln == null) {
      return res.status(400).json({ error: "Faltan campos obligatorios (user_id, variety/name, lat/latitude, lng/longitude)." });
    }

    const result = await db.query(
      `INSERT INTO crops (user_id, variety, lat, lng, area_ha, location_desc, sow_date, notes)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       RETURNING *`,
      [
        targetUser,
        v,
        la,
        ln,
        area_ha ?? null,
        location_desc ?? null,
        sow_date ?? null,   // formato 'YYYY-MM-DD' si lo envías
        notes ?? null
      ]
    );

    res.status(201).json({
      success: true,
      message: "Parcela (crop) creada correctamente.",
      crop: result.rows[0],
    });
  } catch (err) {
    console.error("❌ Error al crear crop:", err);
    // Para depuración temporal devolvemos el mensaje de error en el body
    res.status(500).json({ error: "Error interno al crear el crop/parcela.", detail: err.message });
    // Mira el log con: docker logs node_backend
  }
});

// Listar por usuario
router.get("/api/crops/user/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const uId = parseInt(userId);
    if (req.user.id !== uId && req.user.role !== 'Admin' && req.user.role !== 'Administrador') {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const result = await db.query(
      `SELECT * FROM crops WHERE user_id = $1 ORDER BY id DESC`,
      [uId]
    );
    res.status(200).json({ success: true, crops: result.rows });
  } catch (err) {
    console.error("❌ Error al obtener crops:", err);
    res.status(500).json({ error: "Error interno al obtener los crops/parcela." });
  }
});

// Eliminar cultivo/parcela
router.delete("/api/crops/:id", async (req, res) => {
  try {
    const { id } = req.params;
    await db.query(`DELETE FROM crops WHERE id = $1`, [id]);
    res.status(200).json({ success: true, message: "Crop eliminado correctamente." });
  } catch (err) {
    console.error("❌ Error al eliminar crop:", err);
    res.status(500).json({ error: "Error interno al eliminar el crop/parcela." });
  }
});

  // Obtener diagnosticos por parcela
router.get("/api/crops/:cropId/diagnoses", async (req, res) => {
  try {
    const { cropId } = req.params;

    const result = await db.query(
      `
      SELECT 
        d.*,
        c.variety AS crop_name,
        c.lat AS crop_lat,
        c.lng AS crop_lng
      FROM diagnoses d
      JOIN crops c ON d.crop_id = c.id
      WHERE d.crop_id = $1
      ORDER BY d.created_at DESC
      `,
      [cropId]
    );

    res.json({
      success: true,
      diagnoses: result.rows
    });

  } catch (err) {
    console.error("❌ Error al obtener diagnósticos por parcela:", err);
    res.status(500).json({
      success: false,
      error: "Error al obtener diagnósticos de esta parcela"
    });
  }
});


module.exports = router;
