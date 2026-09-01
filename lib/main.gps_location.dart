import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main(){
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget{
  const MeuApp({super.key});

  @override 
  Widget build(BuildContext context){
    return const MaterialApp( // Adicionado const aqui para boas práticas
      debugShowCheckedModeBanner: false,
      title: 'Minha Localização',
      home: LocalizacaoPage(),
    );
  }
}

class LocalizacaoPage extends StatefulWidget{
  const LocalizacaoPage({super.key});

  @override
  State<LocalizacaoPage> createState() => _LocalizacaoPageState();
}

class _LocalizacaoPageState extends State<LocalizacaoPage>{
  double latitude = 0;
  double longitude = 0;
  double distanciaKM = 0; // 1. CRIADA AQUI para a tela conseguir enxergar!
  
  double latitudeCasa = -21.464389;
  double longitudeCasa = -46.991972;

  Future<void> buscarLocalizacao() async{
    bool servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo){
      await Geolocator.openLocationSettings();
      return;
    }
    LocationPermission permissao = await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied){
      // CORREÇÃO: trocado '==' por '=' para salvar a permissão corretamente
      permissao = await Geolocator.requestPermission(); 
    }
    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever){
      return;
    }
    Position posicao = await Geolocator.getCurrentPosition();

    double distanciaMetros = Geolocator.distanceBetween(
      posicao.latitude,
      posicao.longitude,
      latitudeCasa,
      longitudeCasa,
    );

    // 2. ATUALIZANDO TUDO DENTRO DO SETSTATE para redesenhar a tela
    setState(() {
      latitude = posicao.latitude;
      longitude = posicao.longitude;
      distanciaKM = distanciaMetros / 1000; 
    });

    print('distanciaKM: $distanciaKM');
    print('Latitude: $latitude');
    print('Longitude: $longitude');
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      // CORREÇÃO: Removido um parêntese extra que daria erro no Text
      appBar: AppBar(title: const Text('Minha Localização')), 
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Localização atual do JV',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              // Agora a variável funciona aqui! Usei toStringAsFixed(2) para ficar bonito (ex: 4.25 km)
              Text(
                'A distância do local atual até a minha casa é: ${distanciaKM.toStringAsFixed(2)} km',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text('latitude: $latitude', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Text('longitude: $longitude', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: buscarLocalizacao,
                child: const Text('Atualizar localização'), // Corrigido erro de digitação "Autualizar"
              ),
            ],
          ),
        ),
      ),
    );
  }
}
