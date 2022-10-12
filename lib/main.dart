import 'dart:convert' show base64, utf8;
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:webcrypto/webcrypto.dart';

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
      theme: ThemeData(primarySwatch: Colors.blue),
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
  late Map<String, dynamic> publicKeyJwkA, publicKeyJwkB;
  late Map<String, dynamic> privateKeyJwkA, privateKeyJwkB;

  late Uint8List derivedBitsA, derivedBitsB;
  final Uint8List iv = Uint8List.fromList('Initialization Vector'.codeUnits);

  @override
  void initState() {
    super.initState();
    demo();
  }

  demo() async {
    // Step 1
    await generateKeys();
    // Step 2
    /* Share the public key to other party */

    // Step 3
    derivedBitsA = await createCryptoKey(
      privateJwk: privateKeyJwkA,
      publicKeyJwk: publicKeyJwkB,
    );
    derivedBitsB = await createCryptoKey(
      privateJwk: privateKeyJwkB,
      publicKeyJwk: publicKeyJwkA,
    );

    // Step 4
    String encryptMsg = await encryptMessage(derivedBitsA, "Hello World");
    log("Encrypted Message::::::::::::::::::::::::::::: $encryptMsg");

    // Step 5
    /* Send encrypted message to the database and to receiver */

    // Step 6
    String decryptMsg = await decryptMessage(derivedBitsB, encryptMsg);
    log("Readable Message::::::::::::::::::::::::::::::  $decryptMsg");
  }

  Future<void> generateKeys() async {
    //1. Generate keys
    // For user A
    KeyPair<EcdhPrivateKey, EcdhPublicKey> keyPairA =
        await EcdhPrivateKey.generateKey(EllipticCurve.p256);
    publicKeyJwkA = await keyPairA.publicKey.exportJsonWebKey();
    privateKeyJwkA = await keyPairA.privateKey.exportJsonWebKey();
    KeyPair<EcdhPrivateKey, EcdhPublicKey> keyPairB =
        await EcdhPrivateKey.generateKey(EllipticCurve.p256);
    publicKeyJwkB = await keyPairB.publicKey.exportJsonWebKey();
    privateKeyJwkB = await keyPairB.privateKey.exportJsonWebKey();
  }

  Future<Uint8List> createCryptoKey({
    required Map<String, dynamic> publicKeyJwk,
    required Map<String, dynamic> privateJwk,
  }) async {
    EcdhPublicKey ecdhPublicKey =
        await EcdhPublicKey.importJsonWebKey(publicKeyJwk, EllipticCurve.p256);
    EcdhPrivateKey ecdhPrivateKey =
        await EcdhPrivateKey.importJsonWebKey(privateJwk, EllipticCurve.p256);
    return await ecdhPrivateKey.deriveBits(256, ecdhPublicKey);
  }

  Future<String> encryptMessage(Uint8List derivedBits, String message) async {
    final aesGcmSecretKey = await AesGcmSecretKey.importRawKey(derivedBits);
    List<int> list = message.codeUnits;
    Uint8List data = Uint8List.fromList(list);
    Uint8List encryptedBytes = await aesGcmSecretKey.encryptBytes(data, iv);
    String encryptedString = String.fromCharCodes(encryptedBytes);
    return encryptedString;
  }

  Future<String> decryptMessage(
      Uint8List derivedBits, String encryptMessage) async {
    final aesGcmSecretKey = await AesGcmSecretKey.importRawKey(derivedBits);
    List<int> list = encryptMessage.codeUnits;
    Uint8List data = Uint8List.fromList(list);
    Uint8List decryptedBytes = await aesGcmSecretKey.decryptBytes(data, iv);
    String decryptedString = String.fromCharCodes(decryptedBytes);
    return decryptedString;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: const Center(),
      floatingActionButton: FloatingActionButton(
        onPressed: demo,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
