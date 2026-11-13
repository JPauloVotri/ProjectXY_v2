#region Coleta
    /// @desc Contrato de coleta: cada tipo aplica o efeito e diz se consumiu.
    /// @param {Id.Instance.obj_player} _player Jogador que coletou o pickup.
    /// @return {Bool} true quando o pickup deve sumir.
    on_collect = function(_player) {
        return false;
    }
#endregion
