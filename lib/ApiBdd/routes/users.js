const express = require('express');
const router = express.Router();
const { db } = require('../database/sqlite');
const bcrypt = require('bcryptjs');

// ==========================================
// CRUD UTILISATEURS
// ==========================================

// GET - Récupérer tous les utilisateurs
router.get('/', (req, res) => {
  const sql = `SELECT id, email, ethereum_address, first_name, last_name, phone, created_at, updated_at FROM users ORDER BY created_at DESC`;
  
  db.all(sql, [], (err, rows) => {
    if (err) {
      console.error('Erreur récupération utilisateurs:', err);
      return res.status(500).json({ 
        error: 'Erreur lors de la récupération des utilisateurs',
        details: err.message 
      });
    }
    
    res.json({
      success: true,
      users: rows,
      count: rows.length
    });
  });
});

// GET - Récupérer un utilisateur par ID
router.get('/:id', (req, res) => {
  const userId = req.params.id;
  
  if (!userId || isNaN(parseInt(userId))) {
    return res.status(400).json({ 
      error: 'ID utilisateur invalide' 
    });
  }
  
  const sql = `SELECT id, email, ethereum_address, first_name, last_name, phone, created_at, updated_at FROM users WHERE id = ?`;
  
  db.get(sql, [userId], (err, row) => {
    if (err) {
      console.error('Erreur récupération utilisateur:', err);
      return res.status(500).json({ 
        error: 'Erreur lors de la récupération de l\'utilisateur',
        details: err.message 
      });
    }
    
    if (!row) {
      return res.status(404).json({ 
        error: 'Utilisateur non trouvé' 
      });
    }
    
    res.json({
      success: true,
      user: row
    });
  });
});

// GET - Récupérer un utilisateur par adresse Ethereum
router.get('/address/:address', (req, res) => {
  const address = req.params.address;
  
  if (!address || !address.match(/^0x[a-fA-F0-9]{40}$/)) {
    return res.status(400).json({ 
      error: 'Format d\'adresse Ethereum invalide' 
    });
  }
  
  const sql = `SELECT id, email, ethereum_address, first_name, last_name, phone, created_at, updated_at FROM users WHERE ethereum_address = ?`;
  
  db.get(sql, [address], (err, row) => {
    if (err) {
      console.error('Erreur récupération utilisateur par adresse:', err);
      return res.status(500).json({ 
        error: 'Erreur lors de la récupération de l\'utilisateur',
        details: err.message 
      });
    }
    
    if (!row) {
      return res.status(404).json({ 
        error: 'Utilisateur non trouvé pour cette adresse' 
      });
    }
    
    res.json({
      success: true,
      user: row
    });
  });
});

// POST - Créer un nouvel utilisateur
router.post('/', async (req, res) => {
  try {
    const { email, password, ethereum_address, first_name, last_name, phone } = req.body;
    
    // Validation des champs obligatoires
    if (!email || !password) {
      return res.status(400).json({ 
        error: 'Email et mot de passe requis' 
      });
    }
    
    // Validation de l'adresse Ethereum si fournie
    if (ethereum_address && !ethereum_address.match(/^0x[a-fA-F0-9]{40}$/)) {
      return res.status(400).json({ 
        error: 'Format d\'adresse Ethereum invalide' 
      });
    }
    
    // Validation email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ 
        error: 'Format d\'email invalide' 
      });
    }
    
    // Hachage du mot de passe
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);
    
    const sql = `INSERT INTO users (email, password, ethereum_address, first_name, last_name, phone) VALUES (?, ?, ?, ?, ?, ?)`;
    
    db.run(sql, [email, hashedPassword, ethereum_address, first_name, last_name, phone], function(err) {
      if (err) {
        console.error('Erreur création utilisateur:', err);
        if (err.message.includes('UNIQUE constraint failed')) {
          return res.status(409).json({ 
            error: 'Email ou adresse Ethereum déjà utilisé(e)' 
          });
        }
        return res.status(500).json({ 
          error: 'Erreur lors de la création de l\'utilisateur',
          details: err.message 
        });
      }
      
      res.status(201).json({
        success: true,
        user: {
          id: this.lastID,
          email,
          ethereum_address,
          first_name,
          last_name,
          phone
        },
        message: 'Utilisateur créé avec succès'
      });
    });
    
  } catch (error) {
    console.error('Erreur création utilisateur:', error);
    res.status(500).json({ 
      error: 'Erreur serveur lors de la création de l\'utilisateur',
      details: error.message 
    });
  }
});

// PUT - Mettre à jour un utilisateur
router.put('/:id', async (req, res) => {
  try {
    const userId = req.params.id;
    const { email, password, ethereum_address, first_name, last_name, phone } = req.body;
    
    if (!userId || isNaN(parseInt(userId))) {
      return res.status(400).json({ 
        error: 'ID utilisateur invalide' 
      });
    }
    
    // Validation de l'adresse Ethereum si fournie
    if (ethereum_address && !ethereum_address.match(/^0x[a-fA-F0-9]{40}$/)) {
      return res.status(400).json({ 
        error: 'Format d\'adresse Ethereum invalide' 
      });
    }
    
    // Validation email si fourni
    if (email) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        return res.status(400).json({ 
          error: 'Format d\'email invalide' 
        });
      }
    }
    
    // Construction de la requête de mise à jour dynamique
    let updates = [];
    let values = [];
    
    if (email) {
      updates.push('email = ?');
      values.push(email);
    }
    
    if (password) {
      const saltRounds = 10;
      const hashedPassword = await bcrypt.hash(password, saltRounds);
      updates.push('password = ?');
      values.push(hashedPassword);
    }
    
    if (ethereum_address !== undefined) {
      updates.push('ethereum_address = ?');
      values.push(ethereum_address);
    }
    
    if (first_name !== undefined) {
      updates.push('first_name = ?');
      values.push(first_name);
    }
    
    if (last_name !== undefined) {
      updates.push('last_name = ?');
      values.push(last_name);
    }
    
    if (phone !== undefined) {
      updates.push('phone = ?');
      values.push(phone);
    }
    
    if (updates.length === 0) {
      return res.status(400).json({ 
        error: 'Aucun champ à mettre à jour' 
      });
    }
    
    updates.push('updated_at = CURRENT_TIMESTAMP');
    values.push(userId);
    
    const sql = `UPDATE users SET ${updates.join(', ')} WHERE id = ?`;
    
    db.run(sql, values, function(err) {
      if (err) {
        console.error('Erreur mise à jour utilisateur:', err);
        if (err.message.includes('UNIQUE constraint failed')) {
          return res.status(409).json({ 
            error: 'Email ou adresse Ethereum déjà utilisé(e)' 
          });
        }
        return res.status(500).json({ 
          error: 'Erreur lors de la mise à jour de l\'utilisateur',
          details: err.message 
        });
      }
      
      if (this.changes === 0) {
        return res.status(404).json({ 
          error: 'Utilisateur non trouvé' 
        });
      }
      
      res.json({
        success: true,
        message: 'Utilisateur mis à jour avec succès'
      });
    });
    
  } catch (error) {
    console.error('Erreur mise à jour utilisateur:', error);
    res.status(500).json({ 
      error: 'Erreur serveur lors de la mise à jour de l\'utilisateur',
      details: error.message 
    });
  }
});

// DELETE - Supprimer un utilisateur
router.delete('/:id', (req, res) => {
  const userId = req.params.id;
  
  if (!userId || isNaN(parseInt(userId))) {
    return res.status(400).json({ 
      error: 'ID utilisateur invalide' 
    });
  }
  
  const sql = `DELETE FROM users WHERE id = ?`;
  
  db.run(sql, [userId], function(err) {
    if (err) {
      console.error('Erreur suppression utilisateur:', err);
      return res.status(500).json({ 
        error: 'Erreur lors de la suppression de l\'utilisateur',
        details: err.message 
      });
    }
    
    if (this.changes === 0) {
      return res.status(404).json({ 
        error: 'Utilisateur non trouvé' 
      });
    }
    
    res.json({
      success: true,
      message: 'Utilisateur supprimé avec succès'
    });
  });
});

// POST - Authentification utilisateur
router.post('/auth', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ 
        error: 'Email et mot de passe requis' 
      });
    }
    
    const sql = `SELECT * FROM users WHERE email = ?`;
    
    db.get(sql, [email], async (err, user) => {
      if (err) {
        console.error('Erreur authentification:', err);
        return res.status(500).json({ 
          error: 'Erreur lors de l\'authentification',
          details: err.message 
        });
      }
      
      if (!user) {
        return res.status(401).json({ 
          error: 'Email ou mot de passe incorrect' 
        });
      }
      
      try {
        const passwordMatch = await bcrypt.compare(password, user.password);
        
        if (!passwordMatch) {
          return res.status(401).json({ 
            error: 'Email ou mot de passe incorrect' 
          });
        }
        
        // Retourner les infos utilisateur sans le mot de passe
        const { password: _, ...userInfo } = user;
        
        res.json({
          success: true,
          user: userInfo,
          message: 'Authentification réussie'
        });
        
      } catch (bcryptError) {
        console.error('Erreur bcrypt:', bcryptError);
        res.status(500).json({ 
          error: 'Erreur lors de la vérification du mot de passe' 
        });
      }
    });
    
  } catch (error) {
    console.error('Erreur authentification:', error);
    res.status(500).json({ 
      error: 'Erreur serveur lors de l\'authentification',
      details: error.message 
    });
  }
});

module.exports = router;
