import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'database_helper.dart';

void main() => runApp(AgendaApp());

class AgendaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda de Contatos v2 atualizado master nice bolado',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await DatabaseHelper.instance.getToken();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => token != null ? ContactListScreen() : LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';

  void _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final user = await DatabaseHelper.instance.getUser(_username);
      if (user != null && user.password == _password) {
        await DatabaseHelper.instance.saveToken(_username);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => ContactListScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuário ou senha incorretos')),
        );
      }
    }
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final user = User(username: _username, password: _password);
      try {
        await DatabaseHelper.instance.insertUser(user);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuário cadastrado com sucesso')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao tentar cadastrar usuário!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Usuário'),
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                onSaved: (value) => _username = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                onSaved: (value) => _password = value!,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Entrar'),
                onPressed: _login,
              ),
              TextButton(
                child: Text('Cadastrar'),
                onPressed: _register,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactListScreen extends StatefulWidget {
  @override
  _ContactListScreenState createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  List<Contact> contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final loadedContacts = await DatabaseHelper.instance.getAllContacts();
    setState(() {
      contacts = loadedContacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda de Contatos'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await DatabaseHelper.instance.removeToken();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: contacts.isEmpty
          ? Center(child: Text('Nenhum contato'))
          : ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(contacts[index].name),
            subtitle: Text(contacts[index].phone),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _removeContact(contacts[index].id!),
            ),
            onTap: () => _editContact(contacts[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _addContact,
      ),
    );
  }

  void _addContact() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ContactFormScreen()),
    );
    if (result != null) {
      await DatabaseHelper.instance.insertContact(result);
      _loadContacts();
    }
  }

  void _editContact(Contact contact) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactFormScreen(contact: contact),
      ),
    );
    if (result != null) {
      await DatabaseHelper.instance.updateContact(result);
      _loadContacts();
    }
  }

  void _removeContact(int id) async {
    await DatabaseHelper.instance.deleteContact(id);
    _loadContacts();
  }
}

class ContactFormScreen extends StatefulWidget {
  final Contact? contact;

  ContactFormScreen({this.contact});

  @override
  _ContactFormScreenState createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late int? id;
  late String name;
  late String phone;
  late String email;

  final phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    id = widget.contact?.id;
    name = widget.contact?.name ?? '';
    phone = widget.contact?.phone ?? '';
    email = widget.contact?.email ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact == null ? 'Novo Contato' : 'Editar Contato'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(labelText: 'Nome'),
                validator: (value) => value!.isEmpty ? 'Insira um nome' : null,
                onSaved: (value) => name = value!,
              ),
              TextFormField(
                initialValue: phone,
                decoration: InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
                inputFormatters: [phoneMaskFormatter],
                validator: (value) => value!.length < 14 ? 'Telefone inexistente' : null,
                onSaved: (value) => phone = value!,
              ),
              TextFormField(
                initialValue: email,
                decoration: InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => !value!.contains('@') ? 'E-mail incorreto' : null,
                onSaved: (value) => email = value!,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Salvar'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    Navigator.pop(
                      context,
                      Contact(id: id, name: name, phone: phone, email: email),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}