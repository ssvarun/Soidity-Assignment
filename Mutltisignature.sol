// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    address[] public signers;
    mapping(address => bool) public isSigner;
    uint public requiredConfirmations;

    struct Tx {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint confirmations;
    }

    // mapping from tx index => signer => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Tx[] public transactions;

    modifier onlySigner() {
        require(isSigner[msg.sender], "not signer");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address[] memory _signers, uint _requiredConfirmations) {
        require(_signers.length > 0, "signers required");
        require(
            _requiredConfirmations > 0 &&
                _requiredConfirmations <= _signers.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _signers.length; i++) {
            address signer = _signers[i];

            require(signer != address(0), "invalid signer");
            require(!isSigner[signer], "signer not unique");

            isSigner[signer] = true;
            signers.push(signer);
        }

        requiredConfirmations = _requiredConfirmations;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlySigner {
        uint txIndex = transactions.length;

        transactions.push(
            Tx({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                confirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint _txIndex) public onlySigner
        txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Tx storage transactionInfo = transactions[_txIndex];
        transactionInfo.confirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex) public onlySigner
        txExists(_txIndex) notExecuted(_txIndex) {
        Tx storage transactionInfo = transactions[_txIndex];

        require(
            transactionInfo.confirmations >= requiredConfirmations,
            "cannot execute tx"
        );

        transactionInfo.executed = true;

        (bool success,) = transactionInfo.to.call{value: transactionInfo.value}(
            transactionInfo.data
        );  // ignore unused variable warning

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint _txIndex) public onlySigner
        txExists(_txIndex) notExecuted(_txIndex) {
        Tx storage transactionInfo = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transactionInfo.confirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getSigners() public view returns (address[] memory) {
        return signers;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(
        uint _txIndex
    )
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint confirmations
        )
    {
        Tx storage transactionInfo = transactions[_txIndex];

        return (
            transactionInfo.to,
            transactionInfo.value,
            transactionInfo.data,
            transactionInfo.executed,
            transactionInfo.confirmations
        );
    }
}
