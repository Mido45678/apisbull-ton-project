import "@stdlib/jetton";

contract APISBULL with JettonMintable {
    total_supply: Int as coins;
    burn_tax: Int;
    pharaoh: Address;
    treasury: Address;
    symbol: String;
    decimals: Int;

    init(total_supply: Coins, burn_tax: Int, pharaoh: Address, treasury: Address, symbol: String, decimals: Int) {
        self.total_supply = total_supply;
        self.burn_tax = burn_tax;
        self.pharaoh = pharaoh;
        self.treasury = treasury;
        self.symbol = symbol;
        self.decimals = decimals;
    }

    receive(msg: Cell) {
        let op = msg~loadUint(32);
        
        if (op == 0xf8a7ea5) { // Transfer
            let queryId = msg~loadUint(64);
            let to = msg~loadAddress();
            let amount = msg~loadCoins();
            let forwardTonAmount = msg~loadCoins();
            let forwardPayload = msg~loadMaybeRef();
            
            // Apply tax
            let tax = amount * self.burn_tax / 100;
            let burnAmount = tax / 2;
            let rewardAmount = tax - burnAmount;
            let transferAmount = amount - tax;
            
            // Burn tokens
            self.burn(burnAmount, to);
            
            // Send rewards to treasury
            self.send_reward(rewardAmount);
            
            // Transfer remaining tokens
            self.transfer(transferAmount, to, forwardTonAmount, forwardPayload);
        }
        else if (op == 0x00000000) { // Internal transfer
            // Handle internal transfers
        }
    }

    inline fun burn(amount: Coins, from: Address) {
        // Implement burn logic
        context.log("Burned " + amount.toString() + " tokens from " + from.toString());
        self.total_supply -= amount;
    }

    inline fun send_reward(amount: Coins) {
        // Send rewards to treasury
        context.log("Sent " + amount.toString() + " tokens to treasury");
        self.transfer(amount, self.treasury, toNano(0.01), null);
    }

    inline fun transfer(amount: Coins, to: Address, fwdAmount: Coins, payload: Cell?) {
        // Transfer tokens
        context.log("Transferring " + amount.toString() + " to " + to.toString());
        
        let msg = beginCell()
            .storeUint(0xf8a7ea5, 32) // transfer op
            .storeUint(0, 64) // query_id
            .storeCoins(amount)
            .storeAddress(context.sender)
            .storeAddress(to)
            .storeCoins(fwdAmount)
            .storeMaybeRef(payload)
        .endCell();
        
        send(SendParameters{
            to: to,
            value: fwdAmount,
            body: msg
        });
    }
}