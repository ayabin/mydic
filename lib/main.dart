import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String title = 'My Dic';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      routes: {
        '/': (_) => _LoginPage(),
        '/mypage': (_) => _MyPage(),
        '/addPage': (_) => _AddWordPage(),
      },
    );
  }
}

class _LoginPage extends StatefulWidget {
  @override
  __LoginPageState createState() => __LoginPageState();
}

class __LoginPageState extends State<_LoginPage> {
  String infoText = '';
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'email'),
                onChanged: (String value) {
                  setState(() {
                    email = value;
                  });
                },
              ),
              SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(labelText: 'password'),
                obscureText: true,
                onChanged: (String value) {
                  setState(() {
                    password = value;
                  });
                },
              ),
              SizedBox(height: 48),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text('ログイン'),
                  onPressed: () async {
                    final FirebaseAuth auth = FirebaseAuth.instance;
                    final result = await auth.signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                    await Navigator.of(context).pushReplacementNamed('/mypage');
                  },
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text('新規登録'),
                  onPressed: () async {
                    try {
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final UserCredential result =
                          await auth.createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                      );
                      await Navigator.of(context)
                          .pushReplacementNamed('/mypage');
                    } catch (e) {
                      print(e);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MyPage'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            child: ListTile(
              title: Text('MainTitle'),
              subtitle: Text('SubTitle'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('MainTitle'),
              subtitle: Text('SubTitle'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/addPage');
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class _AddWordPage extends StatefulWidget {
  @override
  __AddWordPageState createState() => __AddWordPageState();
}

class __AddWordPageState extends State<_AddWordPage> {
  String word = '';
  String meaning = '';
  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    // print(auth.currentUser.uid);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Word'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Word'),
                onChanged: (String value) {
                  word = value;
                },
              ),
              SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(labelText: 'Meaning'),
                onChanged: (String value) {
                  meaning = value;
                },
              ),
              SizedBox(height: 48),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final date = DateTime.now().toLocal().toIso8601String();
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(auth.currentUser.uid)
                          .collection('transaction')
                          .doc()
                          .set({
                        'word': word,
                        'meaning': meaning,
                        'date': date,
                      });
                      await Navigator.of(context).pushNamed('/mypage');
                    } catch (e) {
                      print(e);
                    }
                  },
                  child: Text('登録'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
