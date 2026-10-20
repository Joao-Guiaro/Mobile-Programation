// SA03 - Aplicativo Flutter integrado a API RESTful (PHP)
//
// Antes de rodar, adicione a dependência http:
//   flutter pub add http
//
// Se estiver testando no Android, permita HTTP (sem SSL) em
// android/app/src/main/AndroidManifest.xml:
//   <uses-permission android:name="android.permission.INTERNET"/>
//   <application android:usesCleartextTraffic="true" ...>

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// CONFIGURAÇÃO
// ---------------------------------------------------------------------------

/// Endereço informado pelo professor. Altere aqui se mudar.
const String kApiUrl = 'http://10.140.170.33/pdm_api/tarefas.php';

// ---------------------------------------------------------------------------
// MODELO
// ---------------------------------------------------------------------------

class Tarefa {
  final String? id;
  final String titulo;
  final String descricao;
  final String prioridade; // baixa | media | alta
  final String status; // pendente | concluida
  final String? criadoEm;

  static const List<String> prioridades = ['baixa', 'media', 'alta'];
  static const List<String> statusPermitidos = ['pendente', 'concluida'];

  const Tarefa({
    this.id,
    required this.titulo,
    required this.descricao,
    required this.prioridade,
    required this.status,
    this.criadoEm,
  });

  /// Converte o JSON recebido da API em objeto.
  factory Tarefa.fromJson(Map<String, dynamic> json) {
    return Tarefa(
      id: json['id']?.toString(),
      titulo: (json['titulo'] ?? '').toString(),
      descricao: (json['descricao'] ?? '').toString(),
      prioridade: (json['prioridade'] ?? 'media').toString(),
      status: (json['status'] ?? 'pendente').toString(),
      criadoEm: json['criado_em']?.toString(),
    );
  }

  /// Converte o objeto em JSON para enviar (POST / PUT).
  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'descricao': descricao,
        'prioridade': prioridade,
        'status': status,
      };

  bool get concluida => status == 'concluida';
}

// ---------------------------------------------------------------------------
// SERVIÇO (comunicação com a API)
// ---------------------------------------------------------------------------

class ApiException implements Exception {
  final String mensagem;
  ApiException(this.mensagem);

  @override
  String toString() => mensagem;
}

class TarefaService {
  final String baseUrl;
  final Duration timeout;

  TarefaService({this.baseUrl = kApiUrl, this.timeout = const Duration(seconds: 10)});

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  Uri _uri([String? id]) {
    final uri = Uri.parse(baseUrl);
    return id == null ? uri : uri.replace(queryParameters: {'id': id});
  }

  /// Executa a requisição e trata erros de comunicação e de resposta.
  Future<Map<String, dynamic>> _executar(
      Future<http.Response> Function() requisicao) async {
    try {
      final resposta = await requisicao().timeout(timeout);

      Map<String, dynamic> corpo;
      try {
        final decodificado = jsonDecode(utf8.decode(resposta.bodyBytes));
        if (decodificado is! Map<String, dynamic>) {
          throw const FormatException();
        }
        corpo = decodificado;
      } on FormatException {
        throw ApiException(
            'Resposta inválida do servidor (código ${resposta.statusCode}).');
      }

      final ok = resposta.statusCode >= 200 &&
          resposta.statusCode < 300 &&
          corpo['sucesso'] != false;

      if (!ok) {
        throw ApiException(
            (corpo['mensagem'] ?? 'Erro ${resposta.statusCode} no servidor.')
                .toString());
      }
      return corpo;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
          'Tempo esgotado. Verifique se o servidor está ligado e se você está na mesma rede.');
    } on http.ClientException {
      throw ApiException(
          'Não foi possível conectar à API. Verifique o endereço e a rede.');
    } catch (e) {
      throw ApiException('Erro inesperado: $e');
    }
  }

  /// GET - consulta todas as tarefas
  Future<List<Tarefa>> listar() async {
    final corpo = await _executar(() => http.get(_uri(), headers: _headers));
    final dados = corpo['dados'];
    if (dados is! List) return [];
    return dados
        .whereType<Map<String, dynamic>>()
        .map(Tarefa.fromJson)
        .toList();
  }

  /// POST - cadastra uma nova tarefa
  Future<String> cadastrar(Tarefa tarefa) async {
    final corpo = await _executar(() =>
        http.post(_uri(), headers: _headers, body: jsonEncode(tarefa.toJson())));
    return (corpo['mensagem'] ?? 'Tarefa cadastrada com sucesso.').toString();
  }

  /// PUT - altera uma tarefa existente
  Future<String> atualizar(Tarefa tarefa) async {
    if (tarefa.id == null) {
      throw ApiException('A tarefa precisa de um ID para ser alterada.');
    }
    final corpo = await _executar(() => http.put(_uri(tarefa.id),
        headers: _headers, body: jsonEncode(tarefa.toJson())));
    return (corpo['mensagem'] ?? 'Tarefa atualizada com sucesso.').toString();
  }

  /// DELETE - exclui uma tarefa
  Future<String> excluir(String id) async {
    final corpo =
        await _executar(() => http.delete(_uri(id), headers: _headers));
    return (corpo['mensagem'] ?? 'Tarefa excluída com sucesso.').toString();
  }
}

// ---------------------------------------------------------------------------
// APP
// ---------------------------------------------------------------------------

void main() => runApp(const TarefasApp());

class TarefasApp extends StatelessWidget {
  const TarefasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tarefas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F6F6B)),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const ListaTarefasPage(),
    );
  }
}

Color _corPrioridade(String prioridade) {
  switch (prioridade) {
    case 'alta':
      return const Color(0xFFC0392B);
    case 'media':
      return const Color(0xFFD68910);
    default:
      return const Color(0xFF2E8B57);
  }
}

String _rotulo(String valor) {
  switch (valor) {
    case 'media':
      return 'Média';
    case 'concluida':
      return 'Concluída';
    default:
      return valor.isEmpty ? valor : valor[0].toUpperCase() + valor.substring(1);
  }
}

// ---------------------------------------------------------------------------
// TELA: LISTA (GET + DELETE)
// ---------------------------------------------------------------------------

class ListaTarefasPage extends StatefulWidget {
  const ListaTarefasPage({super.key});

  @override
  State<ListaTarefasPage> createState() => _ListaTarefasPageState();
}

class _ListaTarefasPageState extends State<ListaTarefasPage> {
  final TarefaService _service = TarefaService();

  List<Tarefa> _tarefas = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await _service.listar();
      if (!mounted) return;
      setState(() => _tarefas = lista);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mensagem(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        backgroundColor: erro ? Theme.of(context).colorScheme.error : null,
      ));
  }

  Future<void> _abrirFormulario([Tarefa? tarefa]) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FormularioTarefaPage(service: _service, tarefa: tarefa),
      ),
    );
    if (salvou == true) {
      _mensagem(tarefa == null
          ? 'Tarefa cadastrada com sucesso.'
          : 'Tarefa atualizada com sucesso.');
      _carregar();
    }
  }

  Future<void> _excluir(Tarefa tarefa) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir tarefa?'),
        content: Text('"${tarefa.titulo}" será removida permanentemente.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmar != true || tarefa.id == null) return;

    try {
      final msg = await _service.excluir(tarefa.id!);
      if (!mounted) return;
      _mensagem(msg);
      _carregar(); // atualiza a lista após excluir
    } on ApiException catch (e) {
      if (!mounted) return;
      _mensagem(e.mensagem, erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas tarefas'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _carregando ? null : _carregar,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nova tarefa'),
      ),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56),
              const SizedBox(height: 12),
              Text(_erro!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _carregar,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_tarefas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhuma tarefa cadastrada.\nToque em "Nova tarefa" para criar a primeira.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        itemCount: _tarefas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _TarefaCard(
          tarefa: _tarefas[i],
          onEditar: () => _abrirFormulario(_tarefas[i]),
          onExcluir: () => _excluir(_tarefas[i]),
        ),
      ),
    );
  }
}

class _TarefaCard extends StatelessWidget {
  final Tarefa tarefa;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const _TarefaCard({
    required this.tarefa,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final cor = _corPrioridade(tarefa.prioridade);
    final tema = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEditar,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: cor), // faixa de prioridade
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tarefa.titulo,
                        style: tema.textTheme.titleMedium?.copyWith(
                          decoration:
                              tarefa.concluida ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (tarefa.descricao.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(tarefa.descricao,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text('Prioridade ${_rotulo(tarefa.prioridade).toLowerCase()}'),
                            side: BorderSide(color: cor),
                          ),
                          Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: Icon(
                              tarefa.concluida
                                  ? Icons.check_circle
                                  : Icons.schedule,
                              size: 16,
                            ),
                            label: Text(_rotulo(tarefa.status)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEditar,
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onExcluir,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TELA: FORMULÁRIO (POST + PUT)
// ---------------------------------------------------------------------------

class FormularioTarefaPage extends StatefulWidget {
  final TarefaService service;
  final Tarefa? tarefa; // null = cadastro | preenchido = edição

  const FormularioTarefaPage({super.key, required this.service, this.tarefa});

  @override
  State<FormularioTarefaPage> createState() => _FormularioTarefaPageState();
}

class _FormularioTarefaPageState extends State<FormularioTarefaPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descricaoCtrl;
  late String _prioridade;
  late String _status;
  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.tarefa != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tarefa;
    _tituloCtrl = TextEditingController(text: t?.titulo ?? '');
    _descricaoCtrl = TextEditingController(text: t?.descricao ?? '');
    _prioridade = Tarefa.prioridades.contains(t?.prioridade) ? t!.prioridade : 'media';
    _status = Tarefa.statusPermitidos.contains(t?.status) ? t!.status : 'pendente';
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final tarefa = Tarefa(
      id: widget.tarefa?.id,
      titulo: _tituloCtrl.text.trim(),
      descricao: _descricaoCtrl.text.trim(),
      prioridade: _prioridade,
      status: _status,
    );

    try {
      if (_editando) {
        await widget.service.atualizar(tarefa); // PUT
      } else {
        await widget.service.cadastrar(tarefa); // POST
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar tarefa' : 'Nova tarefa')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _tituloCtrl,
                enabled: !_salvando,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o título da tarefa.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoCtrl,
                enabled: !_salvando,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _prioridade,
                decoration: const InputDecoration(labelText: 'Prioridade'),
                items: Tarefa.prioridades
                    .map((p) => DropdownMenuItem(value: p, child: Text(_rotulo(p))))
                    .toList(),
                onChanged: _salvando ? null : (v) => setState(() => _prioridade = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: Tarefa.statusPermitidos
                    .map((s) => DropdownMenuItem(value: s, child: Text(_rotulo(s))))
                    .toList(),
                onChanged: _salvando ? null : (v) => setState(() => _status = v!),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 16),
                Text(_erro!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_editando ? 'Salvar alterações' : 'Cadastrar tarefa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}