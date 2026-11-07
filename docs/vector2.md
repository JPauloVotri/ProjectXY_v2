# Vector2

Vetor 2D para GameMaker, definido em `scripts/scr_vector_2/scr_vector_2.gml`. É um `constructor` com 33 métodos estáticos, sem dependências externas. Requer GML 2.3 ou superior (usa `static` e construtores de struct).

Este documento é a fonte de verdade da API. Os comentários `///` no arquivo alimentam o autocomplete e a validação de tipos do Feather.

## Convenções

Toda a API segue três formas de nome, e essa é a única regra necessária para saber o que um método faz:

| Forma | Exemplos | Efeito | Aloca |
|---|---|---|---|
| **Verbo** | `add`, `rotate`, `ceil`, `normalize` | Muta o vetor e retorna `self` | Não |
| **Particípio** | `added`, `rotated`, `ceiled`, `normalized` | Devolve um **novo** `Vector2` | Sim |
| **Consulta** | `dot`, `magnitude`, `angleTo`, `equals` | Devolve um valor, não muda nada | Não |

Exceções: `clone()` devolve um novo vetor porque é o propósito dele; `set()` e `copyFrom()` mutam porque são escritas; `absolute()` é a única forma adjetiva que não termina em `-ed`.

Como os mutadores retornam `self`, dá para encadear: `vel.normalize().multiply(maxSpeed)`.

**Ângulos são sempre em graus.** A API usa `dcos`, `dsin` e `darccos`, coerente com `direction`, `image_angle`, `point_direction` e `lengthdir_x`/`lengthdir_y`. Ângulo positivo gira no sentido horário, como no resto do GameMaker.

## Referência

### Estado

| Método | Retorna | Aloca | Descrição |
|---|---|---|---|
| `set(_x, _y)` | `Vector2` (self) | Não | Define as componentes. |
| `copyFrom(_other)` | `Vector2` (self) | Não | Copia as componentes de outro vetor. |
| `clone()` | `Vector2` | Sim | Cópia independente. |

### Consultas

| Método | Retorna | Aloca | Descrição |
|---|---|---|---|
| `magnitude()` | `Real` | Não | Comprimento do vetor. |
| `angle()` | `Real` | Não | Direção do vetor, 0 a 360, igual a `direction`. |
| `dot(_other)` | `Real` | Não | Produto escalar. |
| `distanceTo(_other)` | `Real` | Sim¹ | Distância até outro vetor. |
| `angleTo(_other)` | `Real` | Não | Ângulo entre os dois, 0 a 180, sem sinal. |
| `signedAngleTo(_other)` | `Real` | Não | Igual a `angleTo`, mas -180 a 180; positivo é horário. |
| `equals(_other, [_eps])` | `Bool` | Não | Compara componente a componente; `_eps` padrão 0. |
| `toString()` | `String` | Não | Formato `Vector2(x, y)`; aloca string. |

¹ `distanceTo` aloca internamente: chama `subtracted(_other)` e descarta o vetor.

### Aritmética

| Método | Retorna | Aloca | Descrição |
|---|---|---|---|
| `added(_other)` | `Vector2` | Sim | Soma. |
| `add(_other)` | `Vector2` (self) | Não | Soma in-place. |
| `subtracted(_other)` | `Vector2` | Sim | Subtração. |
| `subtract(_other)` | `Vector2` (self) | Não | Subtração in-place. |
| `multiplied(_scalar)` | `Vector2` | Sim | Multiplicação por escalar. |
| `multiply(_scalar)` | `Vector2` (self) | Não | Multiplicação por escalar in-place. |

### Normalização

| Método | Retorna | Aloca | Descrição |
|---|---|---|---|
| `normalized()` | `Vector2` | Sim | Comprimento 1; vetor zero devolve zero. |
| `normalize()` | `Vector2` (self) | Não | Normaliza in-place; vetor zero permanece zero. |

### Rotação

| Método | Retorna | Aloca | Descrição |
|---|---|---|---|
| `rotated(_angle)` | `Vector2` | Sim | Gira em graus. |
| `rotate(_angle)` | `Vector2` (self) | Não | Gira em graus in-place. |

### Interpolação

| Método | Retorna | Aloca | Descrição |
|---|---|---|---|
| `lerped(_other, _t)` | `Vector2` | Sim | Interpolação linear até outro vetor. |
| `lerp(_other, _t)` | `Vector2` (self) | Não | Interpolação linear in-place. |

### Componentes

| Método | Retorna | Aloca | Descrição |
|---|---|---|---|
| `ceiled()` | `Vector2` | Sim | Arredonda para cima. |
| `ceil()` | `Vector2` (self) | Não | Arredonda para cima in-place. |
| `floored()` | `Vector2` | Sim | Arredonda para baixo. |
| `floor()` | `Vector2` (self) | Não | Arredonda para baixo in-place. |
| `rounded()` | `Vector2` | Sim | Arredonda para o inteiro mais próximo. |
| `round()` | `Vector2` (self) | Não | Arredonda para o inteiro mais próximo in-place. |
| `absolute()` | `Vector2` | Sim | Valor absoluto das componentes. |
| `abs()` | `Vector2` (self) | Não | Valor absoluto in-place. |
| `signed()` | `Vector2` | Sim | Sinal de cada componente (-1, 0 ou 1). |
| `sign()` | `Vector2` (self) | Não | Sinal in-place. |

## Armadilhas

- **Graus, não radianos.** `cos`/`sin`/`arctan2` do GML trabalham em radianos; a API usa `dcos`/`dsin`/`darctan2`. Se você misturar as duas famílias, a rotação sai errada por um fator de cerca de 57.
- **`angleTo` não tem sinal.** Ele usa `darccos`, então sempre devolve 0 a 180. Para saber para que lado virar, use `signedAngleTo`.
- **`equals` é exato por padrão.** Comparar floats acumulados com `_eps = 0` costuma falhar; passe uma tolerância.
- **Sombreamento de builtins.** `lerp`, `abs`, `ceil`, `floor`, `round` e `sign` existem tanto como builtins quanto como métodos estáticos. Dentro do próprio método, uma chamada sem `self.` resolve para o builtin — dentro do arquivo isso é intencional. Fora dele, para chamar o estático, use sempre `self.ceil()` ou `v.ceil()`, nunca `ceil()` puro.
- **`distanceTo` aloca.** Ela cria um vetor intermediário. Em loop apertado, compare com `dot` ou calcule manualmente.
- **Vetor zero é tolerado.** `normalize`, `normalized`, `angleTo` e `signedAngleTo` tratam comprimento zero sem dividir por zero.

## Exemplos

Acumular deslocamento sem alocar:

```gml
var _move = new Vector2(0, 0);

_move.add(velocity);
_move.add(wind);

x += _move.x;
y += _move.y;
```

Normalizar input de teclado:

```gml
var _input = new Vector2(
    keyboard_check(vk_right) - keyboard_check(vk_left),
    keyboard_check(vk_down) - keyboard_check(vk_up)
);

if (_input.magnitude() > 0) {
    _input.normalize().multiply(speed);
}

velocity.copyFrom(_input);
```

Girar e converter entre direção e vetor:

```gml
var _forward = new Vector2(1, 0).rotate(45);   // 45 graus, horário
var _angle = _forward.angle();                 // 45
```

Interpolar entre dois pontos:

```gml
var _pos = start.lerped(target, 0.25);
```

Arredondar para a célula de um grid:

```gml
var _cell = new Vector2(x, y)
    .multiplied(1 / grid_size)
    .rounded()
    .multiply(grid_size);
```

Comparar posições com tolerância:

```gml
if (a.equals(b, 0.001)) {
    // praticamente o mesmo ponto
}
```

Distância e ângulo entre dois pontos:

```gml
var _delta = target.subtracted(origin);

if (_delta.magnitude() < _range) {
    var _facing = _delta.angle();
    var _diff = _delta.signedAngleTo(facing);   // -180 a 180; sinal diz o lado
}
```
