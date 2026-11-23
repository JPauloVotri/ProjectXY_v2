#region Contato
    /// @desc Reação ao toque; cada perigo decide o próprio efeito e a invencibilidade.
    /// @param {Id.Instance.obj_player} _player Jogador que encostou.
    /// @return {Bool} `true` quando o toque teve efeito.
    on_touch = function(_player) {
        return false;
    }
#endregion
