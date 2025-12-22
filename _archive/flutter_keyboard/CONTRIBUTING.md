# Guia de Contribuição

Obrigado por considerar contribuir para o Flirt Keyboard! 🎉

## Como Contribuir

### 1. Reportar Bugs

Encontrou um bug? Por favor, abra uma issue com:

- **Título claro** descrevendo o problema
- **Passos para reproduzir** o bug
- **Comportamento esperado** vs **comportamento atual**
- **Screenshots** se aplicável
- **Ambiente**: iOS version, Flutter version, dispositivo

### 2. Sugerir Funcionalidades

Tem uma ideia? Adoraríamos ouvir!

- Abra uma issue com a tag `enhancement`
- Descreva a funcionalidade em detalhes
- Explique o caso de uso
- Se possível, sugira uma implementação

### 3. Pull Requests

#### Antes de Começar

1. Fork o repositório
2. Clone seu fork: `git clone https://github.com/seu-usuario/flirt-keyboard.git`
3. Crie uma branch: `git checkout -b feature/minha-feature`

#### Durante o Desenvolvimento

1. **Mantenha commits pequenos** e focados
2. **Escreva mensagens de commit claras**:
   ```
   feat: adiciona suporte a temas escuros
   fix: corrige crash ao abrir configurações
   docs: atualiza README com instruções de build
   ```
3. **Siga o estilo de código**:
   - Dart: Use `flutter format`
   - Swift: Use SwiftLint (se disponível)
   - TypeScript: Use ESLint

4. **Teste suas mudanças**:
   - Flutter: `flutter test`
   - iOS: Teste em dispositivo real
   - Backend: Teste endpoints

#### Enviando o PR

1. Push para seu fork: `git push origin feature/minha-feature`
2. Abra um Pull Request
3. Preencha o template do PR
4. Aguarde review

### 4. Revisão de Código

- Seja respeitoso e construtivo
- Foque no código, não na pessoa
- Explique o "por quê" das sugestões
- Aprove quando satisfeito

## Estrutura do Código

```
flutter_keyboard/
├── lib/                  # Flutter/Dart code
│   ├── models/          # Data models
│   ├── screens/         # UI screens
│   └── services/        # Business logic
├── ios/                 # iOS native code
│   ├── Runner/          # Main app
│   └── FlirtKeyboardExtension/  # Keyboard extension
└── test/                # Tests
```

## Estilo de Código

### Dart (Flutter)

```dart
// ✅ Bom
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Text('Hello'),
    );
  }
}

// ❌ Ruim
class mywidget extends StatelessWidget {
  @override
  Widget build(context) {
    return Container(
        padding: EdgeInsets.all(16),
        child: Text("Hello"));
  }
}
```

### Swift (iOS)

```swift
// ✅ Bom
private func analyzeText(_ text: String, completion: @escaping (Result<String, Error>) -> Void) {
    // Implementation
}

// ❌ Ruim
func analyzeText(text:String,completion:(Result<String,Error>)->Void){
    // Implementation
}
```

## Mensagens de Commit

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` Nova funcionalidade
- `fix:` Correção de bug
- `docs:` Documentação
- `style:` Formatação
- `refactor:` Refatoração
- `test:` Testes
- `chore:` Manutenção

Exemplos:
```
feat: adiciona seletor de idioma
fix: corrige vazamento de memória no keyboard
docs: atualiza guia de setup do Xcode
```

## Testes

### Flutter

```bash
flutter test
```

### iOS

Teste manualmente em:
- Simulador iOS (funcionalidades básicas)
- Dispositivo real (clipboard, rede)

### Backend

```bash
npm test
```

## Dúvidas?

- Abra uma issue
- Entre em contato: [seu-email@exemplo.com](mailto:seu-email@exemplo.com)

## Código de Conduta

Seja respeitoso, inclusivo e profissional. Não toleramos:
- Linguagem ofensiva
- Assédio
- Discriminação
- Comportamento inadequado

## Licença

Ao contribuir, você concorda que suas contribuições serão licenciadas sob a MIT License.
