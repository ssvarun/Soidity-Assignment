// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Sale is ERC20 {
    address payable owner;
    uint256 tokenforwei;

    uint256 presaleStartTime;
    uint256 presaleEndTime;
    uint256 publicSaleStartTime;
    uint256 publicSaleEndTime;

    uint256 public presaleMinContribution;
    uint256 public presaleMaxContribution;
    uint256 public publicSaleMinContribution;
    uint256 public publicSaleMaxContribution;

    mapping(address => uint256) presaleBalances;
    mapping(address => uint256) publicSaleBalances;

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized access!!");
        _;
    }

    event DebugMsg(string msg, uint256 value);

    function mint(uint256 presaleamount, uint256 publicsaleamount) internal onlyOwner {
        presaleBalances[owner] += presaleamount;
        publicSaleBalances[owner] += publicsaleamount;

        uint256 total = presaleamount + publicsaleamount;
        _mint(owner, total);
    }

    constructor(
        address payable _owner,
        uint256 _tokenforwei,
        uint256 _presaleStartTime,
        uint256 _presaleEndTime,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _presaleMinContribution,
        uint256 _presaleMaxContribution,
        uint256 _publicSaleMinContribution,
        uint256 _publicSaleMaxContribution
    )
        ERC20("Projecttoken", "PT")
    {
        owner = _owner;
        tokenforwei = _tokenforwei;

        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleEndTime;
        publicSaleStartTime = _publicSaleStartTime;
        publicSaleEndTime = _publicSaleEndTime;

        presaleMinContribution = _presaleMinContribution;
        presaleMaxContribution = _presaleMaxContribution;
        publicSaleMinContribution = _publicSaleMinContribution;
        publicSaleMaxContribution = _publicSaleMaxContribution;

        mint(10000, 10000);
    }

    modifier duringPresale() {
        require(
            block.timestamp >= presaleStartTime && block.timestamp <= presaleEndTime,
            "Presale is not active"
        );
        _;
    }

    modifier duringPublicSale() {
        require(
            block.timestamp >= publicSaleStartTime && block.timestamp <= publicSaleEndTime,
            "Public sale is not active"
        );
        _;
    }

    function decimals() public pure override returns (uint8) {
        return 1;
    }

    function calculateToken(uint256 buyerValue) internal view returns (uint256) {
        return buyerValue * tokenforwei;
    }

    function calculateprecap(uint256 tokenamount) internal view returns (uint256, uint256) {
        uint256 minCapEther = (tokenamount * presaleMinContribution);
        uint256 maxCapEther = (tokenamount * presaleMaxContribution);

        return (minCapEther, maxCapEther);
    }

    function calculatePublicSaleCap(uint256 tokenamount) internal view returns (uint256, uint256) {
        uint256 minCapEther = (tokenamount * publicSaleMinContribution);
        uint256 maxCapEther = (tokenamount * publicSaleMaxContribution);

        return (minCapEther, maxCapEther);
    }

    function contriforpresale(uint256 tokenAmount) external payable duringPresale {
        require(
            tokenAmount > presaleMinContribution,
            "Token amount must be greater than Presale Minimum Contribution"
        );
        require(
            tokenAmount < presaleMaxContribution,
            "Token amount should not exceed Presale Maximum Contribution"
        );
        require(msg.sender != owner, "Owner cannot buy tokens, he has to mint them");

        require(msg.value >= tokenAmount, "Insufficient Ether sent");
        require(balanceOf(owner) >= tokenAmount, "Owner does not have enough tokens");

        emit DebugMsg("Token Amount:", tokenAmount);
        // emit DebugMsg("Required Ether:", requiredEther);
        emit DebugMsg("Sent Ether:", msg.value);

        presaleBalances[msg.sender] += tokenAmount;
        presaleBalances[owner] -= tokenAmount;

        _transfer(owner, msg.sender, tokenAmount);
        owner.transfer(msg.value);
    }

    function contriforpublicsale(uint256 tokenAmount) external payable duringPublicSale {
        require(
            tokenAmount > publicSaleMinContribution,
            "Token amount must be greater than Public Sale Minimum Contribution"
        );
        require(
            tokenAmount < publicSaleMaxContribution,
            "Token amount should not exceed Public Sale Maximum Contribution"
        );
        require(msg.sender != owner, "Owner cannot buy tokens, he has to mint them");
        
        uint256 requiredEther = tokenAmount;


        require(msg.value >= requiredEther, "Insufficient Ether sent");
        require(balanceOf(owner) >= tokenAmount, "Owner does not have enough tokens");

        emit DebugMsg("Token Amount:", tokenAmount);
        emit DebugMsg("Required Ether:", requiredEther);
        emit DebugMsg("Sent Ether:", msg.value);

        publicSaleBalances[msg.sender] += tokenAmount;
        publicSaleBalances[owner] -= tokenAmount;

        _transfer(owner, msg.sender, tokenAmount);
        owner.transfer(msg.value);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return presaleBalances[account] + publicSaleBalances[account];
    }

    function claimrefundforpre() external payable {
        require(block.timestamp > presaleEndTime, "Presale not ended yet");
        (, uint256 maxcap) = calculateprecap(msg.value);
        require(address(this).balance < maxcap, "Minimum cap reached");
        uint256 refundAmount = (presaleBalances[msg.sender] * tokenforwei) / 1 ether;
        presaleBalances[msg.sender] = 0;
        payable(msg.sender).transfer(refundAmount);
    }

    function claimRefundForPublicSale() external payable {
        require(block.timestamp > publicSaleEndTime, "Public sale not ended yet");
        (uint256 mincap, ) = calculatePublicSaleCap(msg.value);
        require(address(this).balance < mincap, "Minimum cap reached");

        uint256 refundAmount = (publicSaleBalances[msg.sender] * tokenforwei) / 1 ether;
        publicSaleBalances[msg.sender] = 0;
        payable(msg.sender).transfer(refundAmount);
    }
}
