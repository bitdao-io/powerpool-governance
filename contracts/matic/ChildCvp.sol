pragma solidity ^0.5.16;

import "./ContextMixin.sol";
import "../Cvp.sol";

contract ChildCvp is Cvp, ContextMixin {
  /// @notice Total number of tokens in circulation
  uint96 public totalSupply = 0;
  address public depositor;

  modifier onlyDepositor() {
    require(_msgSender() == depositor, "Cvp::onlyDepositor");
    _;
  }

  constructor(address _depositor) public Cvp(address(0)) {
    depositor = _depositor;
  }

  // This is to support Native meta transactions
  // never use msg.sender directly, use _msgSender() instead
  function _msgSender() internal view returns (address payable sender) {
    return ContextMixin.msgSender();
  }

  /**
   * @notice called when token is deposited on root chain
   * @dev Should be callable only by ChildChainManager
   * Should handle deposit by minting the required amount for user
   * Make sure minting is done only by this function
   * @param user user address for whom deposit is being done
   * @param depositData abi encoded amount
   */
  function deposit(address user, bytes calldata depositData) external onlyDepositor {
    uint256 amount = abi.decode(depositData, (uint256));
    _mint(user, safe96(amount, "Cvp::deposit: amount exceeds 96 bits"));
  }

  /**
   * @notice called when user wants to withdraw tokens back to root chain
   * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
   * @param amount amount of tokens to withdraw
   */
  function withdraw(uint96 amount) external {
    _burn(_msgSender(), amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint96 amount) internal {
    require(account != address(0), "Cvp::_mint: mint to the zero address");

    _moveDelegates(address(0), account, amount);

    totalSupply = add96(totalSupply, amount, "Cvp::_mint: mint amount overflows");
    balances[account] = add96(balances[account], amount, "Cvp::_mint: mint amount overflows");
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint96 amount) internal {
    require(account != address(0), "Cvp::_burn: burn from the zero address");

    _moveDelegates(account, address(0), amount);

    balances[account] = sub96(balances[account], amount, "Cvp::_burn: burn amount exceeds balance");
    totalSupply = sub96(totalSupply, amount, "Cvp::_burn: burn amount exceeds totalSupply");
    emit Transfer(account, address(0), amount);
  }
}