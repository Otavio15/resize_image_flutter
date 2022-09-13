import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imgFlutter;
import 'package:image_picker/image_picker.dart';
import 'package:teste/escolherImagem.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  XFile? imagem;
  int? largura;
  int? altura;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              imagem == null
                  ? Container(
                      height: 150,
                      width: 150,
                      color: Colors.grey.shade300,
                      child: Center(
                        child: Text('Imagem'),
                      ),
                    )
                  : _isLoading == false
                      ? Column(
                          children: [
                            Container(
                              child: Image.file(File(imagem!.path)),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Altura: ${altura.toString()},  Largura: ${largura.toString()}',
                            ),
                          ],
                        )
                      : CircularProgressIndicator(),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  XFile? image = await EscolherImg.escolherImg(context);
                  if (image != null) {
                    print('Veio uma imagem: ' + image.path);
                    File img = File(image!.path);
                    var decodedImage =
                        await decodeImageFromList(img.readAsBytesSync());
                    setState(() {
                      imagem = image;
                      largura = decodedImage.width;
                      altura = decodedImage.height;
                    });
                  } else {
                    print('Não veio imagem');
                  }
                },
                child: const Text('Escolher imagem'),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () async {
                  if (imagem != null) {
                    setState(() {
                      _isLoading = true;
                    });
                    try {
                      //** Redimencionador de imagens  */
                      File image_File = File(imagem!.path);
                      var imagem_nova = await imgFlutter
                          .decodeImage(image_File!.readAsBytesSync());
                      imgFlutter.Image resized_img =
                          imgFlutter.copyResize(imagem_nova!, width: 610);
                      //****************** */

                      //Este código abaixo tá no ponto de mandar para o servidor
                      //*************************************************** */
                      print('Path da imagem ${imagem!.path}');
                      String path = '';
                      List<String> splitPath = imagem!.path.split('/');
                      for (int i = 0; i < splitPath.length - 1; i++) {
                        path += splitPath[i] + '/';
                      }
                      path += 'gabaritosystem.jpeg';
                      print('Novo path ${path}');

                      await File(path)
                        ..writeAsBytesSync(imgFlutter.encodePng(resized_img));

                      var multipartFile = await MultipartFile.fromFile(
                        path,
                        filename: 'gabaritosystem.jpeg',
                        contentType: MediaType("image", "jpeg"),
                      ); //add this);

                      BaseOptions options = BaseOptions(
                          receiveDataWhenStatusError: true,
                          connectTimeout: 60 * 1000, // 60 seconds
                          receiveTimeout: 60 * 1000 // 60 seconds
                          );

                      Dio dio = new Dio(options);

                      dio.options.headers['Content-Type'] =
                          'multipart/form-data';

                      FormData formData = FormData.fromMap(
                        {
                          "image": multipartFile,
                          "flag": "else",
                          "valuethreshold": 10,
                        },
                      );

                      var response = await dio
                          .post(
                            "http://192.168.18.159:5001/upload",
                            data: formData,
                          )
                          .timeout(
                            const Duration(seconds: 60),
                          );

                      if (response.statusCode == 200) {
                        print('Imagem enviada com sucesso');
                        print('Retorno do servidor == ${response.data}');
                      } else {
                        print('Erro ao enviar imagem');
                      }
                    } catch (e) {
                      setState(() {
                        _isLoading = false;
                      });
                      print('Error que deu: ${e}');
                    }
                    setState(() {
                      _isLoading = false;
                    });

                    //*----------------------------
                  } else {
                    const snackBar = SnackBar(
                      content: Text(
                          'Nenhuma imagem encontrada, por favor, escolha uma imagem'),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                },
                child: const Text('Redimencionar imagem e enviar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
