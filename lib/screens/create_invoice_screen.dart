import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/invoice.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final User user;

  const CreateInvoiceScreen({Key? key, required this.user}) : super(key: key);

  @override
  _CreateInvoiceScreenState createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  Invoice? _createdInvoice;

  @override
  void dispose() {
    _clientController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _createdInvoice = null;
    });

    try {
      final invoice = await ApiService.createInvoiceObject(
        merchantAddress: widget.user.identifier,
        clientAddress: _clientController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
      );

      setState(() {
        _createdInvoice = invoice;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Facture ${invoice.shortId} créée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    _clientController.clear();
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _createdInvoice = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une facture'),
        actions: [
          if (_createdInvoice != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetForm,
              tooltip: 'Nouvelle facture',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _createdInvoice != null
            ? _buildSuccessView()
            : _buildCreateForm(),
      ),
    );
  }

  Widget _buildCreateForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Information du marchand
          _buildMerchantInfo(),
          const SizedBox(height: 24),
          
          // Formulaire de création
          _buildFormFields(),
          const SizedBox(height: 24),
          
          // Messages d'erreur
          if (_errorMessage != null) _buildErrorMessage(),
          
          // Bouton de création
          _buildCreateButton(),
        ],
      ),
    );
  }

  Widget _buildMerchantInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations du marchand',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nom: ${widget.user.displayName}',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            'ID: ${widget.user.identifier}',
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: _clientController,
          decoration: const InputDecoration(
            labelText: 'Adresse du client *',
            hintText: 'Entrez l\'adresse Ethereum ou l\'email du client',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez entrer l\'adresse du client';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _amountController,
          decoration: const InputDecoration(
            labelText: 'Montant (USDC) *',
            hintText: 'Ex: 100.50',
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(),
            suffixText: 'USDC',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez entrer le montant';
            }
            final amount = double.tryParse(value.trim());
            if (amount == null || amount <= 0) {
              return 'Veuillez entrer un montant valide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description *',
            hintText: 'Décrivez le produit ou service',
            prefixIcon: Icon(Icons.description),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez entrer une description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _createInvoice,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isLoading
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text('Création en cours...'),
              ],
            )
          : const Text(
              'Créer la facture',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.green[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Facture créée avec succès !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre facture a été enregistrée et est maintenant disponible.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildInvoiceDetails(),
        const SizedBox(height: 24),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildInvoiceDetails() {
    if (_createdInvoice == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails de la facture',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Numéro', _createdInvoice!.shortId),
          _buildDetailRow('Montant', _createdInvoice!.formattedAmount),
          _buildDetailRow('Description', _createdInvoice!.description),
          _buildDetailRow('Client', _createdInvoice!.client),
          _buildDetailRow('Marchand', _createdInvoice!.merchant),
          _buildDetailRow('Statut', _createdInvoice!.statusText),
          _buildDetailRow('Date de création', _formatDate(_createdInvoice!.createdAt)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _resetForm,
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle facture'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.home),
                label: const Text('Retour'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Implémenter le partage de la facture
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité de partage à venir'),
                ),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Partager la facture'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
