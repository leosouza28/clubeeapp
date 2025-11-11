import 'package:app_clubee/services/app_config_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:async';
import '../services/api_service.dart';
import '../services/client_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/titulo_model.dart';
import 'titulo_details_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'criar_acesso_screen.dart';
import 'compliance_screen.dart';
import 'admin_area_screen.dart';
import 'recover_password_screen.dart';
import 'contato_clube_screen.dart';
import 'connected_devices_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isLoggedIn = false;
  final _formKey = GlobalKey<FormState>();
  final _documentController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  UserModel? _currentUser;
  List<TituloModel> _titulos = [];
  bool _isLoadingTitulos = false;
  StreamSubscription<bool>? _unauthorizedLogoutSubscription;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
    _setupUnauthorizedLogoutListener();
  }

  void _setupUnauthorizedLogoutListener() {
    _unauthorizedLogoutSubscription = ApiService.unauthorizedLogoutStream
        .listen((_) {
          debugPrint('🚨 LOGOUT AUTOMÁTICO DETECTADO - Status 401 recebido');
          // Atualizar estado para deslogado após o frame atual
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isLoggedIn = false;
                  _currentUser = null;
                  _titulos = [];
                });
              }
            });
          }
        });
  }

  @override
  void dispose() {
    _documentController.dispose();
    _passwordController.dispose();
    _unauthorizedLogoutSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      final authService = await AuthService.getInstance();
      final isAuthenticated = await authService.isAuthenticated();
      if (isAuthenticated) {
        final user = await authService.getCurrentUser();

        if (user != null) {
          setState(() {
            _isLoggedIn = true;
            _currentUser = user;
          });
          _loadTitulos();
        } else {}
      } else {
        setState(() {
          _isLoggedIn = false;
          _currentUser = null;
          _titulos = [];
        });
      }
    } catch (e) {
      // Erro ao verificar autenticação - usuário não está logado
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoggedIn
          ? _buildLoggedInView(context)
          : _buildLoginView(context),
    );
  }

  Widget _buildLoginView(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // AppBar com gradiente - Área do Cliente
        SliverAppBar(
          expandedHeight: 220,
          floating: false,
          pinned: true,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_circle,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Área do Cliente',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Acesse sua conta para visualizar seus dados',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Conteúdo do formulário de login
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Caso 1: Já possuo conta
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.login,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Já possuo conta',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Campo de documento
                          TextFormField(
                            controller: _documentController,
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                              labelText: 'CPF ou Passaporte',
                              hintText:
                                  'Digite seu CPF ou número do passaporte',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, digite seu documento';
                              }
                              if (value.length < 8) {
                                return 'Documento deve ter pelo menos 8 dígitos';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Campo de senha
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              hintText: 'Digite sua senha',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, digite sua senha';
                              }
                              if (value.length < 4) {
                                return 'Senha deve ter pelo menos 4 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Botão de entrar
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Entrar'),
                          ),
                          const SizedBox(height: 12),

                          // Link para recuperar senha
                          TextButton(
                            onPressed: _showRecoverPasswordDialog,
                            child: const Text('Esqueci minha senha'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Caso 2: Não possuo acesso
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_add,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Não possuo acesso',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Crie seu acesso para acessar todos os nossos serviços.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CriarAcessoScreen(),
                                  ),
                                )
                                .then((resultado) {
                                  // Se retornou true, o usuário completou o cadastro
                                  if (resultado == true) {
                                    _checkAuthenticationStatus();
                                  }
                                });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Criar Acesso'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedInView(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // AppBar com gradiente - Perfil do usuário
        SliverAppBar(
          expandedHeight: 160,
          floating: false,
          pinned: true,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor.withValues(alpha: 0.9),
                    Theme.of(context).primaryColor,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          // Imagem do perfil
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                child:
                                    _currentUser?.profileImagePublic != null &&
                                        _currentUser!
                                            .profileImagePublic!
                                            .isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          _currentUser!.profileImagePublic!,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.person,
                                                  size: 30,
                                                  color: Colors.white,
                                                );
                                              },
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Colors.white,
                                      ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _showChangePhotoDialog,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 14,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),

                          // Informações do usuário
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentUser?.nome ?? 'Usuário',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _currentUser?.cpfCnpj ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
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
              ),
            ),
          ),
        ),

        // Conteúdo da conta logada
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Seção de títulos
                _buildTitulosSection(),
                const SizedBox(height: 24),

                // Seção de funcionalidades internas (apenas se tiver permissões)
                if (_hasAdminPermissions()) ...[
                  _buildInternalFeaturesSection(),
                  const SizedBox(height: 24),
                ],

                // Seção de ações do usuário
                _buildUserActionsSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitulosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.card_membership,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Meus Títulos',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (_isLoadingTitulos)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (_titulos.isEmpty && !_isLoadingTitulos)
          _buildNoTitulosSection()
        else
          Column(
            children: _titulos
                .map((titulo) => _buildTituloCard(titulo))
                .toList(),
          ),
      ],
    );
  }

  // Constrói o card de um título
  Widget _buildTituloCard(TituloModel titulo) {
    final List<Color> gradientColors = titulo.requerAtencao
        ? [Colors.orange.shade300, Colors.deepOrange.shade400]
        : [Colors.white, Colors.blue.shade50];

    return GestureDetector(
      onTap: () => _navigateToTituloDetails(titulo),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: titulo.requerAtencao
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.blue.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: titulo.requerAtencao
              ? Border.all(color: Colors.orange.shade600, width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo.nomeSerie,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: titulo.requerAtencao
                                ? Colors.white
                                : Colors.blue.shade800,
                            shadows: titulo.requerAtencao
                                ? [
                                    const Shadow(
                                      color: Colors.black26,
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Série: ${titulo.tituloSerieHash}',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getTituloStatusColor(titulo),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: _getTituloStatusColor(
                            titulo,
                          ).withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      titulo.statusDisplay,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Seção de datas com ícones
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDateInfo(
                        'Assinatura',
                        _formatDate(titulo.assinatura),
                        Colors.green.shade600,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: _buildDateInfo(
                        'Vencimento',
                        _formatDate(titulo.vencimento),
                        Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Alerta de aceite pendente
              if (titulo.requerAceiteUso && titulo.mostraAceite) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showTermosDeUsoBottomSheet(titulo),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade400,
                          Colors.deepOrange.shade500,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade700,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ação Necessária',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pendente aceitação do plano',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Aviso para títulos que requerem atenção
              if (titulo.requerAtencao) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade400, width: 2),
                  ),
                  child: Row(
                    children: [
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
        ),
      ),
    );
  }

  // Constrói informação de data
  Widget _buildDateInfo(String label, String date, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Retorna a cor do status do título
  Color _getTituloStatusColor(TituloModel titulo) {
    switch (titulo.situacao.toUpperCase()) {
      case 'ATIVO':
        return titulo.bloqueado ? Colors.red : Colors.green;
      case 'PENDENTE':
        return Colors.orange;
      case 'INATIVO':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  // Retorna a mensagem de aviso do título
  String _getTituloWarningMessage(TituloModel titulo) {
    if (titulo.situacao.toUpperCase() == 'PENDENTE') {
      return 'Título pendente - requer atenção';
    }
    if (titulo.situacao.toUpperCase() == 'ATIVO' && titulo.bloqueado) {
      return 'Título bloqueado - procure a administração';
    }
    return 'Requer atenção';
  }

  // Formata uma data para exibição
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Constrói a seção quando não há títulos
  Widget _buildNoTitulosSection() {
    final clientService = ClientService.instance;
    final config = clientService.currentConfig;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.card_membership,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Seja um Associado!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Você ainda não possui é um associado.\nAdquira um de nossos planos e desfrute de todos os benefícios exclusivos do ${config.clientType.displayName}!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Lista de benefícios
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildBenefitItem(
                  'Acesso ilimitado ao parque para você e seus dependentes',
                ),
                _buildBenefitItem(
                  'Participação em eventos exclusivos para associados',
                ),
                _buildBenefitItem(
                  'Lazer em família durante a semana e os finais',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Botão de ação
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAssociacaoInfo,
              icon: const Icon(Icons.star),
              label: const Text('Quero ser um Associado!'),
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
    );
  }

  // Verifica se o usuário tem permissões administrativas
  bool _hasAdminPermissions() {
    return _currentUser?.perfilV2?.scopes.isNotEmpty ?? false;
  }

  // Constrói a seção de funcionalidades internas
  Widget _buildInternalFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shield, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'Funcionalidades Internas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          icon: Icons.admin_panel_settings,
          title: 'Área Administrativa',
          subtitle: 'Acessar painel administrativo',
          color: Colors.deepOrange,
          onTap: _navigateToAdminArea,
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.verified_user,
          title: 'Compliance',
          subtitle: 'Acessar área de compliance',
          color: Colors.purple,
          onTap: _navigateToCompliance,
        ),
      ],
    );
  }

  // Constrói a seção de ações do usuário
  Widget _buildUserActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.settings,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Configurações da Conta',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Cartões de ações
        _buildActionCard(
          icon: Icons.edit,
          title: 'Alterar Dados',
          subtitle: 'Edite suas informações pessoais',
          color: Colors.blue,
          onTap: _showEditProfileDialog,
        ),
        const SizedBox(height: 12),

        _buildActionCard(
          icon: Icons.lock_outline,
          title: 'Alterar Senha',
          subtitle: 'Altere sua senha de acesso',
          color: Colors.green,
          onTap: _showChangePasswordDialog,
        ),
        const SizedBox(height: 12),

        _buildActionCard(
          icon: Icons.devices,
          title: 'Dispositivos Conectados',
          subtitle: 'Gerencie seus dispositivos de acesso',
          color: Colors.purple,
          onTap: _navigateToConnectedDevices,
        ),
        const SizedBox(height: 12),

        _buildActionCard(
          icon: Icons.logout,
          title: 'Sair da Conta',
          subtitle: 'Desconectar do aplicativo',
          color: Colors.red,
          onTap: _handleLogout,
        ),

        const SizedBox(height: 24),

        // Links discretos
        _buildDiscreetLinks(),
      ],
    );
  }

  // Constrói os links discretos (Políticas e Excluir Conta)
  Widget _buildDiscreetLinks() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: _showPrivacyPolicy,
            child: Text(
              'Políticas de Privacidade',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                decoration: TextDecoration.underline,
                decorationColor: Colors.grey[600],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '•',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ),
          InkWell(
            onTap: _showDeleteAccountDialog,
            child: Text(
              'Excluir minha conta',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red[400],
                decoration: TextDecoration.underline,
                decorationColor: Colors.red[400],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Constrói um card de ação
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  // Constrói um item de benefício
  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Handle login
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = await AuthService.getInstance();
      final clientService = ClientService.instance;
      final result = await authService.login(
        clientService.currentConfig.clientType,
        _documentController.text.trim(),
        _passwordController.text.trim(),
      );

      if (result.success) {
        setState(() {
          _isLoggedIn = true;
          _currentUser = result.user;
          _isLoading = false;
        });
        _loadTitulos();
        _showSuccessToast('Login realizado com sucesso!');

        // Verificar acesso após 1 segundo
        Future.delayed(const Duration(seconds: 1), () {
          _verificarAcessoAposLogin();
        });
      } else {
        setState(() {
          _isLoading = false;
        });

        // Verificar se é o caso de criar novo acesso
        final errorMessage = result.error ?? '';
        if (errorMessage.contains('não criou o seu acesso') ||
            errorMessage.contains('ainda não criou')) {
          // Redirecionar para tela de criar acesso
          _navegarParaCriarAcesso();
        } else {
          _showErrorToast(
            result.error ?? 'Credenciais inválidas. Verifique seus dados.',
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorToast('Erro ao fazer login. Tente novamente.');
    }
  }

  // Verificar acesso após login
  Future<void> _verificarAcessoAposLogin() async {
    try {
      final apiService = await ApiService.getInstance();
      final clientService = ClientService.instance;

      final response = await apiService.verificarAcesso(
        clientService.currentConfig.clientType,
      );

      if (response.success) {
        // print('✅ Acesso verificado com sucesso após login');
        if (response.data != null) {
          // print('📊 Dados de acesso: ${response.data}');
        }
      } else {
        // print('⚠️ Erro ao verificar acesso: ${response.error}');
      }
    } catch (e) {
      // print('❌ Erro ao verificar acesso: $e');
    }
  }

  // Navegar para tela de criar acesso
  void _navegarParaCriarAcesso() async {
    final resultado = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CriarAcessoScreen(
          documentoInicial: _documentController.text.trim(),
        ),
      ),
    );

    // Se retornou true, o usuário completou o cadastro
    if (resultado == true) {
      // Aguardar um pouco antes de verificar o status para garantir que o token foi persistido
      await Future.delayed(const Duration(seconds: 1));

      // Tentar verificar autenticação com retry
      int tentativas = 0;
      bool sucesso = false;

      while (tentativas < 3 && !sucesso) {
        tentativas++;
        // debugPrint('🔄 Tentativa $tentativas de verificar autenticação');
        try {
          final authService = await AuthService.getInstance();
          final isAuthenticated = await authService.isAuthenticated();

          if (isAuthenticated) {
            final user = await authService.getCurrentUser();
            if (user != null) {
              setState(() {
                _isLoggedIn = true;
                _currentUser = user;
              });
              // debugPrint(
              //   '✅ Usuário logado com sucesso na tentativa $tentativas',
              // );
              sucesso = true;
              // Aguardar antes de carregar títulos
              await Future.delayed(const Duration(milliseconds: 500));
              _loadTitulos();
            }
          }
        } catch (e) {
          // debugPrint('❌ Erro na tentativa $tentativas: $e');
        }

        if (!sucesso && tentativas < 3) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (!sucesso) {
        // debugPrint('❌ Falha ao verificar autenticação após 3 tentativas');
      }
    } else {
      // debugPrint('❌ Cadastro não foi concluído');
    }
  }

  // Carrega os títulos do usuário
  Future<void> _loadTitulos() async {
    setState(() {
      _isLoadingTitulos = true;
    });

    try {
      final authService = await AuthService.getInstance();
      final clientService = ClientService.instance;
      final titulosResult = await authService.getTitulos(
        clientService.currentConfig.clientType,
      );

      if (titulosResult.success && titulosResult.hasData) {
        final titulos = titulosResult.data!
            .map((tituloJson) => TituloModel.fromJson(tituloJson))
            .toList();
        setState(() {
          _titulos = titulos;
          _isLoadingTitulos = false;
        });
      } else if (titulosResult.isConnectionError) {
        // Erro de conexão - mostrar mensagem específica
        setState(() {
          _titulos = [];
          _isLoadingTitulos = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Falha de conexão: ${titulosResult.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (kDebugMode) {
          print(
            'DEBUG: Resposta vazia ou erro de API - success: ${titulosResult.success}, isConnectionError: ${titulosResult.isConnectionError}, error: ${titulosResult.error}',
          );
        }
        // Resposta vazia ou erro de API - comportamento normal (mostra "Seja um Associado!")
        setState(() {
          _titulos = [];
          _isLoadingTitulos = false;
        });
      }
    } catch (e) {
      setState(() {
        _titulos = [];
        _isLoadingTitulos = false;
      });
    }
  }

  // Handle logout
  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da Conta'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        final authService = await AuthService.getInstance();
        await authService.logout();
        setState(() {
          _isLoggedIn = false;
          _currentUser = null;
          _titulos = [];
          _documentController.clear();
          _passwordController.clear();
        });
        _showSuccessToast('Logout realizado com sucesso!');
      } catch (e) {
        _showErrorToast('Erro ao fazer logout');
      }
    }
  }

  // Navega para tela de detalhes do título
  void _navigateToTituloDetails(TituloModel titulo) {
    // Verificar se requer aceite dos termos antes de navegar
    if (titulo.requerAceiteUso && titulo.mostraAceite) {
      // Mostrar alerta informando que precisa aceitar os termos
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 12),
              const Text('Ação Necessária'),
            ],
          ),
          content: const Text(
            'Você precisa confirmar os termos de uso para utilizar este plano.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showTermosDeUsoBottomSheet(titulo);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Ver Termos'),
            ),
          ],
        ),
      );
      return;
    }

    // Navegar normalmente se não requer aceite
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TituloDetailsScreen(
          tituloId: titulo.id,
          nomeSerie: titulo.nomeSerie,
        ),
      ),
    );
  }

  // Mostra toast de sucesso
  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Mostra toast de erro
  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Mostra dialog de recuperação de senha
  void _showRecoverPasswordDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RecoverPasswordScreen()),
    );
  }

  // Mostra informações sobre como se tornar associado
  void _showAssociacaoInfo() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ContatoClubeScreen()));
  }

  // Mostra dialog para alterar dados do perfil
  void _showEditProfileDialog() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
        )
        .then((result) {
          // Se result for true, significa que os dados foram atualizados
          if (result == true) {
            _loadTitulos(); // Recarrega os dados do usuário
            _checkAuthenticationStatus(); // Atualiza o usuário atual
          }
        });
  }

  // Mostra dialog para alterar foto de perfil
  void _showChangePhotoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        title: Row(
          children: [
            Icon(
              Icons.photo_camera,
              color: Theme.of(context).primaryColor,
              size: 22,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Alterar Foto de Perfil',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escolha uma opção para alterar sua foto de perfil:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.crop, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A imagem será cortada em formato quadrado (1:1)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Opção câmera
              _buildPhotoOptionCard(
                icon: Icons.photo_camera,
                title: 'Tirar Foto',
                subtitle: 'Usar câmera e cortar em formato quadrado',
                color: Colors.blue,
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera();
                },
              ),
              const SizedBox(height: 12),

              // Opção galeria
              _buildPhotoOptionCard(
                icon: Icons.photo_library,
                title: 'Escolher da Galeria',
                subtitle: 'Selecionar e cortar foto existente',
                color: Colors.green,
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  // Constrói um card de opção de foto
  Widget _buildPhotoOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  // Seleciona imagem da câmera
  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100, // Máxima qualidade para o corte
      );

      if (image != null) {
        await _cropAndUploadImage(File(image.path));
      }
    } catch (e) {
      _showErrorToast('Erro ao acessar a câmera');
    }
  }

  // Seleciona imagem da galeria
  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // Máxima qualidade para o corte
      );

      if (image != null) {
        await _cropAndUploadImage(File(image.path));
      }
    } catch (e) {
      _showErrorToast('Erro ao acessar a galeria');
    }
  }

  // Corta a imagem em formato 1:1 e faz upload
  Future<void> _cropAndUploadImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cortar Foto de Perfil',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
            showCropGrid: true,
            cropGridRowCount: 3,
            cropGridColumnCount: 3,
            cropGridColor: Theme.of(
              context,
            ).primaryColor.withValues(alpha: 0.5),
            activeControlsWidgetColor: Theme.of(context).primaryColor,
            dimmedLayerColor: Colors.black.withValues(alpha: 0.5),
            cropFrameColor: Theme.of(context).primaryColor,
            cropFrameStrokeWidth: 2,
          ),
          IOSUiSettings(
            title: 'Cortar Foto de Perfil',
            doneButtonTitle: 'Confirmar',
            cancelButtonTitle: 'Cancelar',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
            hidesNavigationBar: false,
            rectX: 0,
            rectY: 0,
            rectWidth: 0,
            rectHeight: 0,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 520, height: 520),
            dragMode: WebDragMode.move,
            initialAspectRatio: 1.0,
          ),
        ],
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (croppedFile != null) {
        await _uploadProfileImage(File(croppedFile.path));
      }
    } catch (e) {
      _showErrorToast('Erro ao cortar a imagem');
    }
  }

  // Faz upload da imagem de perfil
  Future<void> _uploadProfileImage(File imageFile) async {
    // Mostrar dialog de loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Enviando imagem...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );

    try {
      final authService = await AuthService.getInstance();
      final clientService = ClientService.instance;

      final result = await authService.uploadProfileImage(
        clientService.currentConfig.clientType,
        imageFile,
      );

      // Fechar dialog de loading
      if (mounted) Navigator.of(context).pop();

      if (result.success) {
        // Atualizar a interface
        await _checkAuthenticationStatus();
        _showSuccessToast('Foto de perfil atualizada com sucesso!');
      } else {
        _showErrorToast(result.error ?? 'Erro ao atualizar foto de perfil');
      }
    } catch (e) {
      // Fechar dialog de loading
      if (mounted) Navigator.of(context).pop();
      _showErrorToast('Erro inesperado ao atualizar foto');
    }
  }

  // Navega para a área de Compliance
  void _navigateToCompliance() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ComplianceScreen()));
  }

  // Navega para a Área Administrativa
  void _navigateToAdminArea() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AdminAreaScreen()));
  }

  // Navega para a tela de dispositivos conectados
  void _navigateToConnectedDevices() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ConnectedDevicesScreen()),
    );
  }

  // Mostra informações de contato
  // Navega para tela de alterar senha
  void _showChangePasswordDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
    );
  }

  // Mostra o bottom sheet com os termos de uso
  void _showTermosDeUsoBottomSheet(TituloModel titulo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Título
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.description,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Termos de Uso do Plano ${titulo.nomeSerie}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Conteúdo dos termos (scrollable)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    titulo.termosDeUso ?? 'Termos de uso não disponíveis',
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ),

              const Divider(height: 1),

              // Botões de ação
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Botão Aceitar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmarAceite(titulo, true);
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('ACEITAR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Botão Recusar
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmarAceite(titulo, false);
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text('RECUSAR'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
          ),
        );
      },
    );
  }

  // Confirma a ação de aceitar ou recusar
  void _confirmarAceite(TituloModel titulo, bool aceite) {
    final String tituloText = aceite ? 'Aceitar Plano?' : 'Recusar Plano?';
    final String mensagem = aceite
        ? 'Você confirma que aceita os termos de uso do plano ${titulo.nomeSerie}?'
        : 'ATENÇÃO: Se você recusar este plano, esta ação NÃO PODERÁ SER DESFEITA e o plano será CANCELADO. Deseja continuar?';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                aceite ? Icons.check_circle : Icons.warning,
                color: aceite ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 12),
              Text(tituloText),
            ],
          ),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _aplicarAceite(titulo, aceite);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: aceite ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(aceite ? 'Confirmar Aceite' : 'Confirmar Recusa'),
            ),
          ],
        );
      },
    );
  }

  // Aplica o aceite ou recusa via API
  Future<void> _aplicarAceite(TituloModel titulo, bool aceite) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processando...'),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final clientService = ClientService.instance;
      final authService = await AuthService.getInstance();

      final result = await authService.aplicarAceite(
        clientService.currentConfig.clientType,
        titulo.id,
        aceite,
      );

      // Fechar loading
      if (mounted) Navigator.pop(context);

      if (result.success) {
        if (mounted) {
          _showSuccessToast(
            aceite ? 'Plano aceito com sucesso!' : 'Plano recusado',
          );

          // Recarregar lista de títulos
          _loadTitulos();
        }
      } else {
        if (mounted) {
          _showErrorToast(result.error ?? 'Erro ao processar aceite');
        }
      }
    } catch (e) {
      // Fechar loading
      if (mounted) Navigator.pop(context);

      if (mounted) {
        _showErrorToast('Erro inesperado: $e');
      }
    }
  }

  // Mostra as políticas de privacidade
  void _showPrivacyPolicy() async {
    final appConfigService = AppConfigService.instance;
    final appConfig = appConfigService.appConfig;

    final privacyPolicyUrl = appConfig?.urlSitePoliticaPrivacidade ?? '';

    if (privacyPolicyUrl.isNotEmpty) {
      // Abrir link externo
      try {
        // print('🔗 Abrindo política de privacidade: $privacyPolicyUrl');
        final uri = Uri.parse(privacyPolicyUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } else {
          _showErrorToast('Não foi possível abrir o link.');
        }
      } catch (e) {
        _showErrorToast('Erro ao abrir política de privacidade.');
      }
    }
  }

  // Mostra diálogo de confirmação para excluir conta
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 12),
            const Expanded(child: Text('Excluir Conta')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ATENÇÃO: Esta ação é irreversível!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ao excluir sua conta:\n\n'
                '• Todos os seus dados serão permanentemente removidos\n'
                '• Você perderá acesso aos seus títulos e benefícios\n'
                '• Esta ação NÃO pode ser desfeita\n\n'
                'Se você possui títulos ativos, recomendamos entrar em contato com a administração antes de prosseguir.\n\n'
                'Tem certeza que deseja continuar?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDeleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir Minha Conta'),
          ),
        ],
      ),
    );
  }

  // Confirmação final para excluir conta
  void _confirmDeleteAccount() {
    final TextEditingController confirmController = TextEditingController();
    bool isChecked = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Confirmação Final'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Digite "EXCLUIR" (em letras maiúsculas) para confirmar a exclusão permanente da sua conta:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmController,
                  decoration: const InputDecoration(
                    hintText: 'EXCLUIR',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: isChecked,
                      onChanged: (value) {
                        setState(() {
                          isChecked = value ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'Eu entendo que esta ação é irreversível e todos os meus dados dentro do sistema serão excluídos permanentemente',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                confirmController.dispose();
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isChecked
                  ? () {
                      if (confirmController.text.trim() == 'EXCLUIR') {
                        confirmController.dispose();
                        Navigator.of(context).pop();
                        _executeDeleteAccount();
                      } else {
                        _showErrorToast('Digite "EXCLUIR" para confirmar');
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
                disabledForegroundColor: Colors.white70,
              ),
              child: const Text('Confirmar Exclusão'),
            ),
          ],
        ),
      ),
    ).then((_) => confirmController.dispose());
  }

  // Executa a exclusão da conta
  Future<void> _executeDeleteAccount() async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Excluindo conta...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final authService = await AuthService.getInstance();
      final clientService = ClientService.instance;

      // Chamar o endpoint de exclusão de conta
      final result = await authService.deleteAccount(
        clientService.currentConfig.clientType,
      );

      // Fechar loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result.success) {
        // Atualizar estado após o frame atual para evitar conflitos
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isLoggedIn = false;
                _currentUser = null;
                _titulos = [];
              });
              _showSuccessToast('Conta excluída com sucesso');
            }
          });
        }
      } else {
        if (mounted) {
          _showErrorToast(result.error ?? 'Erro ao excluir conta');
        }
      }
    } catch (e) {
      // Fechar loading
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorToast('Erro inesperado ao excluir conta');
      }
    }
  }
}
