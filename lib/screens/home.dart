// ignore_for_file: unnecessary_import

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController promptController = TextEditingController();
  bool isLoading = false;
  Uint8List? _imageUrl;
  bool isLoadingDownload = false;
  Uuid uuid = const Uuid();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnable = false;
  String _textSpoken = '';
  double _confidentLevel = 0;

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E2E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Image Generator AI 🤖🔥',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: _imageUrl != null
            ? IconButton(
                onPressed: () {
                  promptController.clear();
                  setState(() {
                    _imageUrl = null;
                  });
                },
                icon: const Icon(
                  Icons.history_rounded,
                  color: Color(0xFFA200FF),
                ),
              )
            : Container(),
        actions: [
          _imageUrl != null
              ? isLoadingDownload
                  ? Container(
                      height: 20,
                      width: 20,
                      margin: const EdgeInsets.only(right: 15),
                      child: const CircularProgressIndicator())
                  : IconButton(
                      onPressed: () {
                        saveImage();
                      },
                      icon: const Icon(
                        Icons.download_outlined,
                        color: Color(0xFFA200FF),
                      ),
                    )
              : Container(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: _imageUrl == null
                    ? Lottie.asset(isLoading
                        ? "assets/loading.json"
                        : "assets/ai_logo.json")
                    : Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            width: MediaQuery.sizeOf(context).width,
            color: const Color(0xFF1E1E1E),
            child: SafeArea(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Enter your prompt",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          _speechToText.isListening
                              ? stopListening()
                              : startListening();
                        },
                        icon: Icon(
                            _speechToText.isNotListening
                                ? Icons.mic_off
                                : Icons.mic,
                            color: Colors.white,
                            size: 27))
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF5F5F5F),
                      width: 2,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  child: TextField(
                    controller: promptController,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Write the prompt here...',
                      hintStyle: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF9F9F9F),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child: MaterialButton(
                    minWidth: MediaQuery.sizeOf(context).width,
                    height: 55,
                    color: const Color(0xFFA200FF),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.generating_tokens,
                          color: Colors.white,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Generate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      if (!isLoading) {
                        generateImage();
                      }
                    },
                  ),
                ),
              ],
            )),
          )
        ],
      ),
    );
  }


  
  Future<void> initSpeech() async {
    _speechEnable = await _speechToText.initialize();
  }

  Future<void> startListening() async {
    await _speechToText.listen(onResult: onSpeechResult);
    setState(() {
      _confidentLevel = 0;
    });
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void onSpeechResult(result) {
    setState(() {
      _textSpoken = "${result.recognizedWords}";
      promptController.text = _textSpoken;
      _confidentLevel = result.confidence;
    });
  }

  void generateImage() async {
    if (promptController.text.isNotEmpty) {
      setState(() {
        isLoading = true;
        _imageUrl = null;
      });
      String engineId = "stable-diffusion-v1-6";
      String apiHost = 'https://api.stability.ai';
      String apiKey = 'sk-qA5E26m41clhcPOdBDj1q805D7URPUO9rwPvIMcLaJc6nsIV';
      debugPrint(promptController.text);
      final response = await http.post(
          Uri.parse('$apiHost/v1/generation/$engineId/text-to-image'),
          headers: {
            "Content-Type": "application/json",
            "Accept": "image/png",
            "Authorization": "Bearer $apiKey"
          },
          body: jsonEncode({
            "text_prompts": [
              {
                "text": promptController.text,
                "weight": 1,
              }
            ],
            "cfg_scale": 7,
            "height": 1024,
            "width": 1024,
            "samples": 1,
            "steps": 30,
          }));

      if (response.statusCode == 200) {
        try {
          Uint8List imageData;
          debugPrint(response.statusCode.toString());
          imageData = response.bodyBytes;
          setState(() {
            _imageUrl = imageData;
            isLoading = false;
          });
        } on Exception {
          setState(() {
            isLoading = false;
          });
          debugPrint("failed to generate image");
        }
      } else {
        setState(() {
          isLoading = false;
        });
        debugPrint("failed to generate image");
      }
    }
  }

  Future<void> saveImage() async {
    if (_imageUrl != null) {
      setState(() {
        isLoadingDownload = true;
      });
      final result = await ImageGallerySaverPlus.saveImage(_imageUrl!,
          quality: 100, name: uuid.v4());
      if (kDebugMode) {
        print(result);
      }
      setState(() {
        isLoadingDownload = false;
        if (result["isSuccess"]) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              'Image saved successfully ✅',
              style: TextStyle(color: Color(0xFFA200FF)),
            ),
            behavior: SnackBarBehavior.fixed,
            backgroundColor: Color(0xFF1E1E1E),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              'Image not saved successfully ',
              style: TextStyle(color: Color(0xFFA200FF)),
            ),
            behavior: SnackBarBehavior.fixed,
            backgroundColor: Color(0xFF1E1E1E),
          ));
        }
      });
    }
  }

}
