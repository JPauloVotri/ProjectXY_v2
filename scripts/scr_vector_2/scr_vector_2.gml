/// @desc Vetor 2D.
///
/// Convenção de nomes: verbo (`add`, `rotate`, `ceil`) muta o vetor e retorna `self`;
/// particípio (`added`, `rotated`, `ceiled`) devolve um NOVO vetor; consulta (`dot`,
/// `magnitude`, `equals`) devolve valor e não aloca. Ângulos sempre em graus.
///
/// Guia completo: `docs/vector2.md`.
function Vector2(_x = 0, _y = 0) constructor {
    x = _x;
    y = _y;

    #region Estado
        /// @desc Define as componentes e retorna self.
        /// @param {Real} _x
        /// @param {Real} _y
        /// @return {Struct.Vector2} self
        static set = function (_x, _y) {
            x = _x;
            y = _y;
            return self;
        }

        /// @desc Copia as componentes de outro vetor e retorna self.
        /// @param {Struct.Vector2} _other Vetor de origem.
        /// @return {Struct.Vector2} self
        static copyFrom = function (_other) {
            x = _other.x;
            y = _other.y;
            return self;
        }

        /// @desc Cria uma cópia independente deste vetor.
        /// @return {Struct.Vector2} novo vetor
        static clone = function () {
            return new Vector2(x, y);
        }
    #endregion

    #region Consultas
        /// @desc Comprimento do vetor.
        /// @return {Real}
        static magnitude = function () {
            return sqrt(sqr(x) + sqr(y));
        }

        /// @desc Direção do vetor em graus (0 a 360, horário, igual a `direction`).
        /// @return {Real}
        static angle = function () {
            return point_direction(0, 0, x, y);
        }

        /// @desc Produto escalar com outro vetor.
        /// @param {Struct.Vector2} _other
        /// @return {Real}
        static dot = function (_other) {
            return x * _other.x + y * _other.y;
        }

        /// @desc Distância até outro vetor.
        /// @param {Struct.Vector2} _other
        /// @return {Real}
        static distanceTo = function (_other) {
            return self.subtracted(_other).magnitude();
        }

        /// @desc Ângulo entre os dois vetores, em graus, sempre entre 0 e 180.
        /// @param {Struct.Vector2} _other
        /// @return {Real}
        static angleTo = function (_other) {
            var _len_a = self.magnitude();
            var _len_b = _other.magnitude();

            if (_len_a == 0 || _len_b == 0) return 0;

            var _cos = self.dot(_other) / (_len_a * _len_b);
            _cos = clamp(_cos, -1, 1);

            return darccos(_cos);
        }

        /// @desc Como `angleTo`, mas com sinal: positivo é horário no screen space.
        /// @param {Struct.Vector2} _other
        /// @return {Real} entre -180 e 180
        static signedAngleTo = function (_other) {
            var _a = self.angleTo(_other);

            if (_a == 0) return 0;

            return _a * sign(x * _other.y - y * _other.x);
        }

        /// @desc Compara componente a componente, com tolerância opcional.
        /// @param {Struct.Vector2} _other
        /// @param {Real} [_eps] Tolerância por componente; padrão 0.
        /// @return {Bool}
        static equals = function (_other, _eps = 0) {
            return abs(x - _other.x) <= _eps && abs(y - _other.y) <= _eps;
        }

        /// @desc Representação textual no formato `Vector2(x, y)`.
        /// @return {String}
        static toString = function () {
            return "Vector2(" + string(x) + ", " + string(y) + ")";
        }
    #endregion

    #region Aritmética
        /// @desc Soma outro vetor e devolve um novo vetor.
        /// @param {Struct.Vector2} _other
        /// @return {Struct.Vector2} novo vetor
        static added = function (_other) {
            return new Vector2(x + _other.x, y + _other.y);
        }

        /// @desc Soma outro vetor in-place e retorna self.
        /// @param {Struct.Vector2} _other
        /// @return {Struct.Vector2} self
        static add = function (_other) {
            x += _other.x;
            y += _other.y;
            return self;
        }

        /// @desc Subtrai outro vetor e devolve um novo vetor.
        /// @param {Struct.Vector2} _other
        /// @return {Struct.Vector2} novo vetor
        static subtracted = function (_other) {
            return new Vector2(x - _other.x, y - _other.y);
        }

        /// @desc Subtrai outro vetor in-place e retorna self.
        /// @param {Struct.Vector2} _other
        /// @return {Struct.Vector2} self
        static subtract = function (_other) {
            x -= _other.x;
            y -= _other.y;
            return self;
        }

        /// @desc Multiplica as componentes por um escalar e devolve um novo vetor.
        /// @param {Real} _scalar
        /// @return {Struct.Vector2} novo vetor
        static multiplied = function (_scalar) {
            return new Vector2(x * _scalar, y * _scalar);
        }

        /// @desc Multiplica as componentes por um escalar in-place e retorna self.
        /// @param {Real} _scalar
        /// @return {Struct.Vector2} self
        static multiply = function (_scalar) {
            x *= _scalar;
            y *= _scalar;
            return self;
        }
    #endregion

    #region Normalização
        /// @desc Devolve um novo vetor de mesmo sentido e comprimento 1. Vetor zero devolve zero.
        /// @return {Struct.Vector2} novo vetor
        static normalized = function () {
            var _len = self.magnitude();

            if (_len == 0) return new Vector2(0, 0);

            return new Vector2(x / _len, y / _len);
        }

        /// @desc Normaliza in-place e retorna self. Vetor zero permanece zero.
        /// @return {Struct.Vector2} self
        static normalize = function () {
            var _len = self.magnitude();

            if (_len != 0) {
                x /= _len;
                y /= _len;
            }

            return self;
        }
    #endregion

    #region Rotação
        /// @desc Gira o vetor em graus e devolve um novo vetor.
        /// @param {Real} _angle Graus; positivo é horário.
        /// @return {Struct.Vector2} novo vetor
        static rotated = function (_angle) {
            var _cos = dcos(_angle);
            var _sin = dsin(_angle);

            return new Vector2(
                x * _cos - y * _sin,
                x * _sin + y * _cos
            );
        }

        /// @desc Gira o vetor em graus in-place e retorna self.
        /// @param {Real} _angle Graus; positivo é horário.
        /// @return {Struct.Vector2} self
        static rotate = function (_angle) {
            var _cos = dcos(_angle);
            var _sin = dsin(_angle);
            var _x = x * _cos - y * _sin;
            var _y = x * _sin + y * _cos;

            return self.set(_x, _y);
        }
    #endregion

    #region Interpolação
        /// @desc Interpola linearmente até outro vetor e devolve um novo vetor.
        /// @param {Struct.Vector2} _other Vetor de destino.
        /// @param {Real} _t Fator de 0 a 1.
        /// @return {Struct.Vector2} novo vetor
        static lerped = function (_other, _t) {
            return new Vector2(
                lerp(x, _other.x, _t),
                lerp(y, _other.y, _t)
            );
        }

        /// @desc Interpola linearmente até outro vetor in-place e retorna self.
        /// @param {Struct.Vector2} _other Vetor de destino.
        /// @param {Real} _t Fator de 0 a 1.
        /// @return {Struct.Vector2} self
        static lerp = function (_other, _t) {
            var _x = lerp(x, _other.x, _t);
            var _y = lerp(y, _other.y, _t);

            return self.set(_x, _y);
        }
    #endregion

    #region Componentes
        /// @desc Arredonda as componentes para cima e devolve um novo vetor.
        /// @return {Struct.Vector2} novo vetor
        static ceiled = function () {
            return new Vector2(ceil(x), ceil(y));
        }

        /// @desc Arredonda as componentes para cima in-place e retorna self.
        /// @return {Struct.Vector2} self
        static ceil = function () {
            return self.set(ceil(x), ceil(y));
        }

        /// @desc Arredonda as componentes para baixo e devolve um novo vetor.
        /// @return {Struct.Vector2} novo vetor
        static floored = function () {
            return new Vector2(floor(x), floor(y));
        }

        /// @desc Arredonda as componentes para baixo in-place e retorna self.
        /// @return {Struct.Vector2} self
        static floor = function () {
            return self.set(floor(x), floor(y));
        }

        /// @desc Arredonda as componentes para o inteiro mais próximo e devolve um novo vetor.
        /// @return {Struct.Vector2} novo vetor
        static rounded = function () {
            return new Vector2(round(x), round(y));
        }

        /// @desc Arredonda as componentes para o inteiro mais próximo in-place e retorna self.
        /// @return {Struct.Vector2} self
        static round = function () {
            return self.set(round(x), round(y));
        }

        /// @desc Devolve o valor absoluto das componentes em um novo vetor.
        /// @return {Struct.Vector2} novo vetor
        static absolute = function () {
            return new Vector2(abs(x), abs(y));
        }

        /// @desc Aplica valor absoluto nas componentes in-place e retorna self.
        /// @return {Struct.Vector2} self
        static abs = function () {
            return self.set(abs(x), abs(y));
        }

        /// @desc Devolve o sinal de cada componente (-1, 0 ou 1) em um novo vetor.
        /// @return {Struct.Vector2} novo vetor
        static signed = function () {
            return new Vector2(sign(x), sign(y));
        }

        /// @desc Aplica sinal nas componentes in-place e retorna self.
        /// @return {Struct.Vector2} self
        static sign = function () {
            return self.set(sign(x), sign(y));
        }
    #endregion
}
