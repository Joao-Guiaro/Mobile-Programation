import 'package:flutter/material.dart';

void main() {
  runApp(const MeuApp());
}

// ======================================================
// MODELO DE MOVIMENTAÇÃO
// ======================================================

class Movimentacao {
  String descricao;
  double valor;
  bool entrada;
  String data;

  Movimentacao({
    required this.descricao,
    required this.valor,
    required this.entrada,
    required this.data,
  });
}

// ======================================================
// APP
// ======================================================

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Controle Financeiro',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
        ),
        useMaterial3: true,
      ),

      home: const HomePage(),
    );
  }
}

// ======================================================
// HOME PAGE
// ======================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// ======================================================
// ESTADO DA HOME
// ======================================================

class _HomePageState extends State<HomePage> {

  // Lista de movimentações
  final List<Movimentacao> movimentacoes = [

    Movimentacao(
      descricao: 'Salário',
      valor: 3000,
      entrada: true,
      data: '01/08/2026',
    ),

    Movimentacao(
      descricao: 'Mercado',
      valor: 120,
      entrada: false,
      data: 'Hoje',
    ),

    Movimentacao(
      descricao: 'Internet',
      valor: 100,
      entrada: false,
      data: '02/08/2026',
    ),

    Movimentacao(
      descricao: 'Transporte',
      valor: 80,
      entrada: false,
      data: '03/08/2026',
    ),
  ];

  // ====================================================
  // CALCULAR ENTRADAS
  // ====================================================

  double get totalEntradas {

    double total = 0;

    for (var movimentacao in movimentacoes) {

      if (movimentacao.entrada) {
        total += movimentacao.valor;
      }

    }

    return total;
  }

  // ====================================================
  // CALCULAR SAÍDAS
  // ====================================================

  double get totalSaidas {

    double total = 0;

    for (var movimentacao in movimentacoes) {

      if (!movimentacao.entrada) {
        total += movimentacao.valor;
      }

    }

    return total;
  }

  // ====================================================
  // CALCULAR SALDO
  // ====================================================

  double get saldo {

    return totalEntradas - totalSaidas;

  }

  // ====================================================
  // ADICIONAR MOVIMENTAÇÃO
  // ====================================================

  void adicionarMovimentacao(
    String descricao,
    double valor,
    bool entrada,
  ) {

    setState(() {

      movimentacoes.insert(
        0,

        Movimentacao(
          descricao: descricao,
          valor: valor,
          entrada: entrada,
          data: 'Hoje',
        ),
      );

    });

  }

  // ====================================================
  // JANELA PARA ADICIONAR
  // ====================================================

  void abrirAdicionar() {

    showModalBottomSheet(
      context: context,

      builder: (context) {

        return SafeArea(

          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [

                const Text(
                  'Adicionar movimentação',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // ========================================
                // ENTRADA
                // ========================================

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(

                    onPressed: () {

                      Navigator.pop(context);

                      abrirFormulario(true);

                    },

                    icon: const Icon(
                      Icons.arrow_downward,
                      color: Colors.green,
                    ),

                    label: const Text(
                      'Adicionar Entrada',
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ========================================
                // SAÍDA
                // ========================================

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(

                    onPressed: () {

                      Navigator.pop(context);

                      abrirFormulario(false);

                    },

                    icon: const Icon(
                      Icons.arrow_upward,
                      color: Colors.red,
                    ),

                    label: const Text(
                      'Adicionar Saída',
                    ),
                  ),
                ),

                const SizedBox(height: 10),

              ],
            ),
          ),
        );
      },
    );
  }

  // ====================================================
  // FORMULÁRIO
  // ====================================================

  void abrirFormulario(bool entrada) {

    final descricaoController =
        TextEditingController();

    final valorController =
        TextEditingController();

    showDialog(

      context: context,

      builder: (context) {

        return AlertDialog(

          title: Text(
            entrada
                ? 'Nova Entrada'
                : 'Nova Saída',
          ),

          content: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              // DESCRIÇÃO
              TextField(

                controller: descricaoController,

                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Ex: Salário',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              // VALOR
              TextField(

                controller: valorController,

                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),

                decoration: const InputDecoration(
                  labelText: 'Valor',
                  hintText: 'Ex: 500',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(),
                ),
              ),

            ],
          ),

          actions: [

            // CANCELAR
            TextButton(

              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'Cancelar',
              ),
            ),

            // ADICIONAR
            ElevatedButton(

              onPressed: () {

                final descricao =
                    descricaoController.text;

                final valor =
                    double.tryParse(
                      valorController.text
                          .replaceAll(',', '.'),
                    );

                if (descricao.isEmpty ||
                    valor == null ||
                    valor <= 0) {

                  return;

                }

                adicionarMovimentacao(
                  descricao,
                  valor,
                  entrada,
                );

                Navigator.pop(context);
              },

              child: const Text(
                'Adicionar',
              ),
            ),

          ],
        );
      },
    );
  }

  // ====================================================
  // HOME
  // ====================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      // ==================================================
      // MENU LATERAL
      // ==================================================

      drawer: Drawer(

        child: ListView(

          padding: EdgeInsets.zero,

          children: [

            // CABEÇALHO
            DrawerHeader(

              decoration: const BoxDecoration(
                color: Colors.red,
              ),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: const [

                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 45,
                  ),

                  SizedBox(height: 10),

                  Text(
                    'Controle Financeiro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    'Organize seu dinheiro',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),

                ],
              ),
            ),

            // INÍCIO
            ListTile(

              leading: const Icon(
                Icons.home,
              ),

              title: const Text(
                'Início',
              ),

              onTap: () {

                Navigator.pop(context);

              },
            ),

            // MOVIMENTAÇÕES
            ListTile(

              leading: const Icon(
                Icons.receipt_long,
              ),

              title: const Text(
                'Movimentações',
              ),

              onTap: () {

                Navigator.pop(context);

              },
            ),

            // RELATÓRIOS
            ListTile(

              leading: const Icon(
                Icons.bar_chart,
              ),

              title: const Text(
                'Relatórios',
              ),

              onTap: () {

                Navigator.pop(context);

              },
            ),

            // CONFIGURAÇÕES
            ListTile(

              leading: const Icon(
                Icons.settings,
              ),

              title: const Text(
                'Configurações',
              ),

              onTap: () {

                Navigator.pop(context);

              },
            ),

          ],
        ),
      ),

      // ==================================================
      // TOPO
      // ==================================================

      appBar: AppBar(

        title: const Text(
          'Controle Financeiro',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: Colors.red,

        foregroundColor: Colors.white,

      ),

      // ==================================================
      // CORPO
      // ==================================================

      body: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ==================================================
            // SALDO
            // ==================================================

            Card(
            
              color: Colors.green,

              child: Padding(

                padding: const EdgeInsets.all(20),

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    const Text(
                      'Saldo atual',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(

                      'R\$ ${saldo.toStringAsFixed(2).replaceAll('.', ',')}',

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // ENTRADAS E SAÍDAS
            // ==================================================

            Row(

              children: [

                // ENTRADAS
                Expanded(

                  child: Card(

                    child: Padding(

                      padding:
                          const EdgeInsets.all(16),

                      child: Column(

                        children: [

                          const Icon(
                            Icons.arrow_downward,
                            color: Colors.green,
                            size: 30,
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Entradas',
                          ),

                          const SizedBox(height: 5),

                          Text(

                            'R\$ ${totalEntradas.toStringAsFixed(2).replaceAll('.', ',')}',

                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // SAÍDAS
                Expanded(

                  child: Card(

                    child: Padding(

                      padding:
                          const EdgeInsets.all(16),

                      child: Column(

                        children: [

                          const Icon(
                            Icons.arrow_upward,
                            color: Colors.red,
                            size: 30,
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Saídas',
                          ),

                          const SizedBox(height: 5),

                          Text(

                            'R\$ ${totalSaidas.toStringAsFixed(2).replaceAll('.', ',')}',

                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ),

              ],
            ),

            const SizedBox(height: 25),

            // ==================================================
            // TÍTULO
            // ==================================================

            const Text(

              'Últimas movimentações',

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // ==================================================
            // LISTA
            // ==================================================

            Expanded(

              child: ListView.builder(

                itemCount: movimentacoes.length,

                itemBuilder: (context, index) {

                  final movimentacao =
                      movimentacoes[index];

                  return ListTile(

                    leading: CircleAvatar(

                      backgroundColor:
                          movimentacao.entrada
                              ? Colors.green.shade100
                              : Colors.red.shade100,

                      child: Icon(

                        movimentacao.entrada
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,

                        color:
                            movimentacao.entrada
                                ? Colors.green
                                : Colors.red,
                      ),
                    ),

                    title: Text(
                      movimentacao.descricao,
                    ),

                    subtitle: Text(
                      movimentacao.data,
                    ),

                    trailing: Text(

                      '${movimentacao.entrada ? '+' : '-'} '
                      'R\$ ${movimentacao.valor.toStringAsFixed(2).replaceAll('.', ',')}',

                      style: TextStyle(

                        color:
                            movimentacao.entrada
                                ? Colors.green
                                : Colors.red,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ==================================================
      // BOTÃO +
      // ==================================================

      floatingActionButton:

          FloatingActionButton(

        backgroundColor: Colors.red,

        foregroundColor: Colors.white,

        onPressed: abrirAdicionar,

        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }
}