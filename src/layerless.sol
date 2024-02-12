// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { OApp, Origin, MessagingFee } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";


import {ERC404} from "./ERC404.sol";

contract LayerLess is ERC404, OApp {
    using OptionsBuilder for bytes;

    string  private _tokenURI;

    event MessageSent(address src,bytes32 to,uint256 amount );
    constructor(address _endpoint,
    string memory name_,
    string memory symbol_,
    uint8 decimals_ ,
    uint256 maxTotalSupplyERC721_) 
    ERC404(name_, symbol_, decimals_) OApp(_endpoint, msg.sender)  {
    // Do not mint the ERC721s to the initial owner, as it's a waste of gas.
    _setWhitelist(msg.sender, true);
    _mintERC20(msg.sender, maxTotalSupplyERC721_ * units, false);
    }


  function tokenURI(uint256 id_) public view override returns (string memory) {
    return _tokenURI;
  }

  function settokenURI (string memory tokenurl) public onlyOwner {
    _tokenURI = tokenurl;
  }

  function setMainchain (bool mainchain) public onlyOwner {
    mainChain = mainchain;
  }

  function setNFTExamt (address pool , bool value) public onlyOwner {
      _setWhitelist(pool, value);
  }
/* @dev Quotes the gas needed to pay for the full omnichain transaction.
 * @return nativeFee Estimated gas fee in native gas.
 * @return lzTokenFee Estimated gas fee in ZRO token.
 */
function quote(
    uint32 _dstEid, // Destination chain's endpoint ID.
    bytes32 to,
    uint256 amount,
    uint256 [] memory ids,// The message to send.
    uint128 gas, // Message execution options
    bool _payInLzToken // boolean for which token to return fee in
) public view returns (uint256 nativeFee, uint256 lzTokenFee) {
     if(gas < 200000) revert NotEnoughGas();

     bytes memory _payload = abi.encode(to,amount,_minted,ids);
     bytes memory _options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(gas, 0);
    MessagingFee memory fee = _quote(_dstEid, _payload, _options, _payInLzToken);
    return (fee.nativeFee, fee.lzTokenFee);
}

    // Sends a message from the source to destination chain.
function send(uint32 _dstEid, bytes32 to,uint256 amount, uint128 gas) external payable {
        if(gas < 200000) revert NotEnoughGas();
  uint256 minted = _minted;
   uint256 [] memory ids = burnForCrossChain(msg.sender,amount);
    bytes memory _options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(gas, 0);

    bytes memory _payload = abi.encode(to,amount,minted,ids); // Encodes message as bytes.
    _lzSend(
        _dstEid, // Destination chain's endpoint ID.
        _payload, // Encoded message payload being sent.
        _options, // Message execution options (e.g., gas to use on destination).
        MessagingFee(msg.value, 0), // Fee struct containing native gas and ZRO token.
        payable(msg.sender) // The refund address in case the send call reverts.
    );

    emit MessageSent(address(this),to,amount);
    
}

function _lzReceive(
    Origin calldata _origin, // struct containing info about the message sender
    bytes32 _guid, // global packet identifier
    bytes calldata payload, // encoded message payload being received
    address _executor, // the Executor address.
    bytes calldata _extraData // arbitrary data appended by the Executor
    ) internal override {
         (bytes32 _to, uint256 amount , uint256 minted, uint256 [] memory ids ) = abi.decode(payload, (bytes32, uint256,uint256,uint256[])); 
         address toAddress;
         toAddress = address(uint160(uint256(_to)));

        mintForCrossChain (toAddress,amount,minted,ids);

}



}