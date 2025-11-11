import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/titulo_details_model.dart';
import '../services/client_service.dart';
import '../services/auth_service.dart';
import '../widgets/pdf_viewer_modal.dart';
import 'atribuir_dependente_screen.dart';
import 'nova_reserva_screen.dart';
import 'reservas_screen.dart';
import 'cobrancas_screen.dart';

class TituloDetailsScreen extends StatefulWidget {
  final String tituloId;
  final String nomeSerie;

  const TituloDetailsScreen({
    super.key,
    required this.tituloId,
    required this.nomeSerie,
  });

  @override
  State<TituloDetailsScreen> createState() => _TituloDetailsScreenState();
}

class _TituloDetailsScreenState extends State<TituloDetailsScreen> {
  TituloDetailsModel? _tituloDetails;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTituloDetails();
  }

  Future<void> _loadTituloDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final clientService = ClientService.instance;
      final authService = await AuthService.getInstance();

      final result = await authService.getTituloDetails(
        clientService.currentConfig.clientType,
        widget.tituloId,
      );

      if (result.success && result.data != null) {
        setState(() {
          _tituloDetails = TituloDetailsModel.fromJson(result.data!);
          _isLoading = false;
        });
      } else if (result.isConnectionError) {
        setState(() {
          _error = 'Falha de conexão: ${result.error}';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error =
              result.error ?? 'Não foi possível carregar os detalhes do título';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro inesperado: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nomeSerie),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando detalhes do título...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadTituloDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_tituloDetails == null) {
      return const Center(child: Text('Nenhum detalhe encontrado'));
    }

    // Se título não estiver ativo, mostrar apenas cobranças
    final isTituloAtivo = _isTituloAtivo();

    return RefreshIndicator(
      onRefresh: _loadTituloDetails,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTituloHeader(),
            const SizedBox(height: 16),

            // Mostrar alerta se título não estiver ativo
            if (!isTituloAtivo) ...[
              _buildAcessoBloqueadoCard(),
              const SizedBox(height: 16),
            ],

            // Contrato Digital sempre visível
            _buildContratoDigitalSection(),
            const SizedBox(height: 16),

            // Cobranças sempre visível
            _buildCobrancasSection(),
            const SizedBox(height: 16),

            // Demais seções apenas se título estiver ativo
            if (isTituloAtivo) ...[
              _buildReservarConvidadosSection(),
              const SizedBox(height: 16),
              _buildMinhasReservasSection(),
              const SizedBox(height: 16),
              _buildTitularSection(),
              const SizedBox(height: 16),
              _buildDependentesSection(),
              const SizedBox(height: 16),
              _buildCortesiasSection(),
              const SizedBox(height: 16),
              _buildVendedorSection(),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTituloHeader() {
    final titulo = _tituloDetails!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: titulo.requerAtencao
              ? [Colors.orange.shade300, Colors.deepOrange.shade400]
              : [Colors.blue.shade400, Colors.cyan.shade300],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (titulo.requerAtencao ? Colors.orange : Colors.blue)
                .withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo.nomeSerie,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  titulo.statusDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: titulo.requerAtencao
                        ? Colors.orange.shade700
                        : Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Primeira linha: Série e Título
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Série',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            titulo.tituloSerieHash.isNotEmpty
                                ? titulo.codSerie
                                : 'N/A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Título',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            titulo.titulo.isNotEmpty ? titulo.titulo : 'N/A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                // Segunda linha: Assinatura e Vencimento
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assinatura',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatDate(titulo.assinatura),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Vencimento',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatDate(titulo.vencimento),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (titulo.requerAtencao) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade400, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getTituloWarningMessage(titulo),
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTitularSection() {
    final titular = _tituloDetails!.titular;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Titular',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
                  child:
                      titular.carteirinhaFoto != null &&
                          titular.carteirinhaFoto!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            titular.carteirinhaFoto!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 30,
                                color: Theme.of(context).primaryColor,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: Theme.of(context).primaryColor,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titular.nome.isNotEmpty
                            ? titular.nome
                            : 'Nome não informado',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (titular.idade > 0 || titular.genero.isNotEmpty)
                        Text(
                          [
                            if (titular.idade > 0) '${titular.idade} anos',
                            if (titular.genero.isNotEmpty) titular.genero,
                          ].join(' • '),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      if (titular.hash.isNotEmpty)
                        Text(
                          'Hash: ${titular.hash}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Seção específica para dados da carteirinha
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.card_membership,
                        color: Colors.blue.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Carteirinha',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getCarteirinhaStatusBackgroundColor(
                            titular.carteirinhaEmitida,
                            titular.temCarteirinhaValida,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getCarteirinhaStatus(
                            titular.carteirinhaEmitida,
                            titular.temCarteirinhaValida,
                          ),
                          style: TextStyle(
                            color: _getCarteirinhaStatusColor(
                              titular.carteirinhaEmitida,
                              titular.temCarteirinhaValida,
                            ),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (titular.carteirinhaHash != null &&
                      titular.carteirinhaHash!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Hash: ${titular.carteirinhaHash}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  if (titular.carteirinhaEmitida) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status: Emitida',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              if (titular.carteirinhaDataEmissao != null)
                                Text(
                                  'Data: ${_formatDate(titular.carteirinhaDataEmissao!)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (titular.carteirinhaUrl != null &&
                            titular.carteirinhaUrl!.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () {
                              _viewCarteirinhaPDF(titular.carteirinhaUrl!);
                            },
                            icon: Icon(Icons.picture_as_pdf, size: 14),
                            label: Text(
                              'Ver Carteirinha',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade600,
                              side: BorderSide(
                                color: Colors.red.shade600,
                                width: 1.5,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Botão para gerar carteirinha
            if (titular.titularCanAddFoto) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showGerarCarteirinhaOptions(),
                  icon: const Icon(Icons.add_a_photo, size: 20),
                  label: const Text(
                    'Gerar Carteirinha',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDependentesSection() {
    final dependentesAtivos = _tituloDetails!.dependentesAtivos;
    final dependentesLivres = _tituloDetails!.dependentesLivres;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Dependentes',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${dependentesAtivos.length} ativos',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (dependentesAtivos.isEmpty && dependentesLivres.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    const Text('Nenhum dependente cadastrado'),
                  ],
                ),
              )
            else if (dependentesAtivos.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nenhum dependente ativo - há vagas disponíveis',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...dependentesAtivos
                  .map((dep) => _buildDependenteCard(dep))
                  .toList(),

            if (dependentesLivres.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Vagas Livres (${dependentesLivres.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...dependentesLivres
                  .map((dep) => _buildVagaLivreCard(dep))
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDependenteCard(DependenteModel dependente) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Primeira linha: Dados pessoais
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.1),
                child:
                    dependente.carteirinhaFoto != null &&
                        dependente.carteirinhaFoto!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          dependente.carteirinhaFoto!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 20,
                              color: Theme.of(context).primaryColor,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dependente.nome.isNotEmpty
                          ? dependente.nome
                          : 'Nome não informado',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (dependente.dataNasc != null && dependente.idade > 0)
                      Text(
                        '${dependente.idade} anos',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    if (dependente.parentesco.isNotEmpty)
                      Text(
                        dependente.parentesco,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Segunda linha: Dados da carteirinha (se existir)
          if (dependente.carteirinhaHash != null &&
                  dependente.carteirinhaHash!.isNotEmpty ||
              dependente.carteirinhaEmitida ||
              dependente.carteirinhaUrl != null &&
                  dependente.carteirinhaUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.card_membership,
                        color: Colors.blue.shade700,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Carteirinha',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getCarteirinhaStatusBackgroundColor(
                            dependente.carteirinhaEmitida,
                            dependente.temCarteirinhaValida,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getCarteirinhaStatus(
                            dependente.carteirinhaEmitida,
                            dependente.temCarteirinhaValida,
                          ),
                          style: TextStyle(
                            color: _getCarteirinhaStatusColor(
                              dependente.carteirinhaEmitida,
                              dependente.temCarteirinhaValida,
                            ),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (dependente.carteirinhaHash != null &&
                      dependente.carteirinhaHash!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Hash: ${dependente.carteirinhaHash}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  if (dependente.carteirinhaUrl != null &&
                      dependente.carteirinhaUrl!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            _viewCarteirinhaPDF(dependente.carteirinhaUrl!);
                          },
                          icon: Icon(Icons.picture_as_pdf, size: 14),
                          label: Text(
                            'Ver Carteirinha',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                            side: BorderSide(
                              color: Colors.red.shade600,
                              width: 1.5,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        if (dependente.carteirinhaEmitida) ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              _showTrocarFotoDependenteOptions(dependente);
                            },
                            icon: Icon(Icons.photo_camera, size: 14),
                            label: Text(
                              'Trocar Foto',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade600,
                              side: BorderSide(
                                color: Colors.blue.shade600,
                                width: 1.5,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVagaLivreCard(DependenteModel vaga) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.add_circle_outline, color: Colors.green.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vaga disponível',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (vaga.hash.isNotEmpty)
                  Text(
                    'Hash: ${vaga.hash}',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AtribuirDependenteScreen(
                    tituloId: widget.tituloId,
                    dependenteHash: vaga.hash,
                  ),
                ),
              );

              if (result == true) {
                // Recarrega os detalhes do título
                _loadTituloDetails();
              }
            },
            icon: Icon(Icons.person_add, size: 16),
            label: Text(
              'Atribuir',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade700,
              side: BorderSide(color: Colors.green.shade700, width: 1.5),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCortesiasSection() {
    final cortesias = _tituloDetails!.pacoteCortesias;
    final totalDisponiveis = _tituloDetails!.totalCortesiasDisponiveis;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pacote de Cortesias',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: totalDisponiveis > 0
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalDisponiveis disponíveis',
                    style: TextStyle(
                      color: totalDisponiveis > 0 ? Colors.green : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (cortesias.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    const Text('Nenhum pacote de cortesias'),
                  ],
                ),
              )
            else
              ...cortesias
                  .map((cortesia) => _buildCortesiaCard(cortesia))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCortesiaCard(PacoteCortesiaModel cortesia) {
    final isAtiva = cortesia.situacao.toUpperCase() == 'ATIVADO';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAtiva
              ? [Colors.purple.shade400, Colors.pink.shade300]
              : [Colors.grey.shade300, Colors.grey.shade400],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cortesia.descricao.isNotEmpty
                      ? cortesia.descricao
                      : 'Cortesia',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${cortesia.quantidade}',
                  style: TextStyle(
                    color: isAtiva
                        ? Colors.purple.shade700
                        : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (cortesia.periodo.isNotEmpty)
            Text(
              cortesia.periodo,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          if (cortesia.situacao.isNotEmpty)
            Text(
              'Status: ${cortesia.situacao}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVendedorSection() {
    final vendedor = _tituloDetails!.vendedor;

    if (vendedor == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_pin, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Vendedor',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendedor.nome.isNotEmpty
                            ? vendedor.nome
                            : 'Nome não informado',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (vendedor.email.isNotEmpty)
                        Text(
                          vendedor.email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      if (vendedor.numeroTelefoneAcesso.isNotEmpty)
                        Text(
                          vendedor.numeroTelefoneAcesso,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservarConvidadosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_add, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Reservar Convidados',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Reserve espaços para seus convidados no clube',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NovaReservaScreen(
                        tituloId: widget.tituloId,
                        tituloNome: widget.nomeSerie,
                      ),
                    ),
                  );

                  if (result == true) {
                    // Reserva criada com sucesso - pode atualizar a tela se necessário
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Navegue para "Minhas Reservas" para visualizar',
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Efetuar Reserva'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinhasReservasSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_note, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Minhas Reservas',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Visualize suas reservas ativas e canceladas para este título',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ReservasScreen(
                        tituloId: widget.tituloId,
                        tituloNome: widget.nomeSerie,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.list),
                label: const Text('Ver Todas as Reservas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCobrancasSection() {
    final pendencias = _tituloDetails!.pendenciasFinanceiras;
    final isEmDia = pendencias?.isEmDia ?? true;
    final qtdPendencias = pendencias?.qtdPendencias ?? 0;
    final valorPendencias = pendencias?.valorPendencias ?? 0.0;
    final statusPendencia = pendencias?.statusPendencia ?? 'EM DIA';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Cobranças',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isEmDia
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusPendencia,
                    style: TextStyle(
                      color: isEmDia
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isEmDia
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isEmDia
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isEmDia ? Icons.check_circle : Icons.warning,
                              color: isEmDia
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pendências',
                              style: TextStyle(
                                color: isEmDia
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'R\$ ${valorPendencias.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isEmDia
                                ? Colors.black87
                                : Colors.red.shade700,
                          ),
                        ),
                        if (qtdPendencias > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$qtdPendencias ${qtdPendencias == 1 ? 'pendência' : 'pendências'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CobrancasScreen(
                        tituloId: widget.tituloId,
                        tituloNome: widget.nomeSerie,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text('Cobranças do Plano'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcessoBloqueadoCard() {
    final titulo = _tituloDetails!;
    String mensagem = '';

    if (titulo.bloqueado) {
      mensagem =
          'Título bloqueado. Entre em contato com a administração para regularizar sua situação.';
    } else if (titulo.situacao.toUpperCase() != 'ATIVO') {
      mensagem =
          'Título ${titulo.situacao.toLowerCase()}. Regularize sua situação para acessar todas as funcionalidades.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.deepOrange.shade500],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.block, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Acesso Restrito',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mensagem,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Verifique suas cobranças abaixo',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildContratoDigitalSection() {
    final titulo = _tituloDetails!;
    final contratoAssinatura = titulo.contratoDigitalAssinaturaCliente;
    final contratoStatus = titulo.contratoDigitalStatus;
    final contratoLinkAssinado = titulo.contratoDigitalLinkAssinado;

    // Se não há nenhuma informação de contrato, não mostra a seção
    if (contratoAssinatura == null &&
        contratoStatus == null &&
        contratoLinkAssinado == null) {
      return const SizedBox.shrink();
    }

    // Determinar o estado do contrato
    bool isAssinaturaClientePendente = contratoAssinatura?.isPendente ?? false;
    bool isContratoAssinado = contratoStatus?.toUpperCase() == 'ASSINADO';
    bool isPendenteSecretaria =
        contratoStatus?.toUpperCase() == 'PENDENTE SECRETARIA';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Contrato Digital',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isContratoAssinado
                        ? Colors.green.withValues(alpha: 0.1)
                        : isPendenteSecretaria
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    contratoStatus?.toUpperCase() ?? 'PENDENTE',
                    style: TextStyle(
                      color: isContratoAssinado
                          ? Colors.green.shade700
                          : isPendenteSecretaria
                          ? Colors.orange.shade700
                          : Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Assinatura do cliente pendente
            if (isAssinaturaClientePendente &&
                contratoAssinatura?.link != null &&
                contratoAssinatura!.link!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.pending_actions,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Assinatura Pendente',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Você precisa assinar o contrato digital para completar o processo.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _abrirLinkExterno(
                          contratoAssinatura.link!,
                          'Contrato Digital',
                        ),
                        icon: const Icon(Icons.edit_document, size: 20),
                        label: const Text(
                          'Assinar Contrato',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Pendente na secretaria
            if (isPendenteSecretaria && !isAssinaturaClientePendente) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aguardando assinatura da secretaria',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Contrato assinado
            if (isContratoAssinado &&
                contratoLinkAssinado != null &&
                contratoLinkAssinado.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Contrato Assinado',
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seu contrato foi assinado por todas as partes.',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _abrirLinkExterno(
                          contratoLinkAssinado,
                          'Contrato Assinado',
                        ),
                        icon: Icon(
                          Icons.open_in_new,
                          size: 20,
                          color: Colors.green.shade700,
                        ),
                        label: Text(
                          'Visualizar Contrato',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.green.shade700,
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _abrirLinkExterno(String url, String descricao) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível abrir $descricao'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir link: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Mostra opções para gerar carteirinha
  Future<void> _showGerarCarteirinhaOptions() async {
    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final clientService = ClientService.instance;
    final clientType = clientService.currentConfig.clientType;
    final authService = await AuthService.getInstance();

    // Verifica se usuário tem foto de perfil
    bool hasProfilePhoto = false;
    String? profilePhotoUrl;

    try {
      final result = await authService.getLoggedUserImage(clientType);
      if (result.success &&
          result.imageUrl != null &&
          result.imageUrl!.isNotEmpty) {
        hasProfilePhoto = true;
        profilePhotoUrl = result.imageUrl;
      }
    } catch (e) {
      // Ignora erro, apenas não mostra a opção
    }

    if (!mounted) return;

    // Remove loading
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Escolha a foto para carteirinha',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: const Text('Galeria'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.green),
                  title: const Text('Câmera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
                if (hasProfilePhoto)
                  ListTile(
                    leading: const Icon(
                      Icons.account_circle,
                      color: Colors.orange,
                    ),
                    title: const Text('Usar foto do perfil'),
                    onTap: () {
                      Navigator.pop(context);
                      _useProfilePhoto(profilePhotoUrl!);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // Escolhe imagem da galeria
  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _cropAndUploadImage(pickedFile.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao selecionar imagem: $e')));
    }
  }

  // Escolhe imagem da câmera
  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _cropAndUploadImage(pickedFile.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao capturar imagem: $e')));
    }
  }

  // Recorta e faz upload da imagem
  Future<void> _cropAndUploadImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar Foto',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Recortar Foto',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        await _uploadTitularPhoto(File(croppedFile.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao recortar imagem: $e')));
    }
  }

  // Usa foto do perfil
  Future<void> _useProfilePhoto(String profilePhotoUrl) async {
    if (!mounted) return;

    // Mostra dialog de confirmação
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text(
          'Deseja usar sua foto de perfil para gerar a carteirinha?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _atribuirFotoTitular(profilePhotoUrl);
    }
  }

  // Faz upload da foto do titular
  Future<void> _uploadTitularPhoto(File imageFile) async {
    if (!mounted) return;

    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final clientService = ClientService.instance;
      final clientType = clientService.currentConfig.clientType;
      final authService = await AuthService.getInstance();

      // Upload da imagem
      final uploadResult = await authService.uploadOutOfDb(
        clientType,
        imageFile,
      );

      if (!mounted) return;
      Navigator.pop(context); // Remove loading

      if (uploadResult.success && uploadResult.url != null) {
        await _atribuirFotoTitular(uploadResult.url!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(uploadResult.error ?? 'Erro ao fazer upload da foto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Remove loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Atribui foto ao titular
  Future<void> _atribuirFotoTitular(String photoUrl) async {
    if (!mounted) return;

    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final clientService = ClientService.instance;
      final clientType = clientService.currentConfig.clientType;
      final authService = await AuthService.getInstance();

      final result = await authService.atribuirTitularFoto(
        clientType,
        widget.tituloId,
        photoUrl,
      );

      if (!mounted) return;
      Navigator.pop(context); // Remove loading

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto atribuída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        // Recarrega os detalhes do título
        _loadTituloDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Erro ao atribuir foto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Remove loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Mostra opções para trocar foto do dependente
  Future<void> _showTrocarFotoDependenteOptions(
    DependenteModel dependente,
  ) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trocar foto de ${dependente.nome}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: const Text('Galeria'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGalleryDependente(dependente);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.green),
                  title: const Text('Câmera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCameraDependente(dependente);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // Escolhe imagem da galeria para dependente
  Future<void> _pickImageFromGalleryDependente(
    DependenteModel dependente,
  ) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _cropAndUploadImageDependente(pickedFile.path, dependente);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao selecionar imagem: $e')));
    }
  }

  // Escolhe imagem da câmera para dependente
  Future<void> _pickImageFromCameraDependente(
    DependenteModel dependente,
  ) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _cropAndUploadImageDependente(pickedFile.path, dependente);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao capturar imagem: $e')));
    }
  }

  // Recorta e faz upload da imagem do dependente
  Future<void> _cropAndUploadImageDependente(
    String imagePath,
    DependenteModel dependente,
  ) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar Foto',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Recortar Foto',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        await _uploadDependentePhoto(File(croppedFile.path), dependente);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao recortar imagem: $e')));
    }
  }

  // Faz upload da foto do dependente
  Future<void> _uploadDependentePhoto(
    File imageFile,
    DependenteModel dependente,
  ) async {
    if (!mounted) return;

    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final clientService = ClientService.instance;
      final clientType = clientService.currentConfig.clientType;
      final authService = await AuthService.getInstance();

      // Upload da imagem
      final uploadResult = await authService.uploadOutOfDb(
        clientType,
        imageFile,
      );

      if (!mounted) return;
      Navigator.pop(context); // Remove loading

      if (uploadResult.success && uploadResult.url != null) {
        await _atribuirFotoDependente(uploadResult.url!, dependente);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(uploadResult.error ?? 'Erro ao fazer upload da foto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Remove loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Atribui foto ao dependente
  Future<void> _atribuirFotoDependente(
    String photoUrl,
    DependenteModel dependente,
  ) async {
    if (!mounted) return;

    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final clientService = ClientService.instance;
      final clientType = clientService.currentConfig.clientType;
      final authService = await AuthService.getInstance();

      final result = await authService.atribuirVagaFoto(
        clientType,
        widget.tituloId,
        dependente.hash,
        photoUrl,
      );

      if (!mounted) return;
      Navigator.pop(context); // Remove loading

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto de ${dependente.nome} atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        // Recarrega os detalhes do título
        _loadTituloDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Erro ao atualizar foto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Remove loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewCarteirinhaPDF(String pdfUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PDFViewerModal(pdfUrl: pdfUrl, title: 'Carteirinha PDF');
      },
    );
  }

  String _getTituloWarningMessage(TituloDetailsModel titulo) {
    if (titulo.situacao.toUpperCase() == 'PENDENTE') {
      return 'Título pendente - requer atenção';
    }
    if (titulo.situacao.toUpperCase() == 'ATIVO' && titulo.bloqueado) {
      return 'Título bloqueado - procure a administração';
    }
    return 'Requer atenção';
  }

  // Verifica se o título permite acesso às funcionalidades
  bool _isTituloAtivo() {
    if (_tituloDetails == null) return false;
    return _tituloDetails!.situacao.toUpperCase() == 'ATIVO' &&
        !_tituloDetails!.bloqueado;
  }

  // Função auxiliar para determinar o status da carteirinha
  String _getCarteirinhaStatus(bool emitida, bool valida) {
    if (!emitida) {
      return 'Não emitida';
    }
    return valida ? 'Válida' : 'Vencida';
  }

  // Função auxiliar para determinar a cor do status da carteirinha
  Color _getCarteirinhaStatusColor(bool emitida, bool valida) {
    if (!emitida) {
      return Colors.orange;
    }
    return valida ? Colors.green : Colors.red;
  }

  // Função auxiliar para determinar a cor de fundo do status da carteirinha
  Color _getCarteirinhaStatusBackgroundColor(bool emitida, bool valida) {
    if (!emitida) {
      return Colors.orange.withValues(alpha: 0.1);
    }
    return valida
        ? Colors.green.withValues(alpha: 0.1)
        : Colors.red.withValues(alpha: 0.1);
  }
}
