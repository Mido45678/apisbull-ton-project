import "@stdlib/deploy";
import "./jetton.tact";

contract Presale with Deployable {
    token: APISBULL;
    rate: Int; // Tokens per TON
    start_time: Int;
    end_time: Int;
    min_purchase: Coins;
    max_purchase: Coins;
    collected: Coins;

    init(token: APISBULL, rate: Int, start_time: Int, end_time: Int, min_purchase: Coins, max_purchase: Coins) {
        self.token = token;
        self.rate = rate;
        self.start_time = start_time;
        self.end_time = end_time;
        self.min_purchase = min_purchase;
        self.max_purchase = max_purchase;
        self.collected = toNano(0);
    }

    receive() {
        let now = context.now;
        require(now >= self.start_time, "Sale not started");
        require(now <= self.end_time, "Sale ended");
        
        let amount = context.value;
        require(amount >= self.min_purchase, "Amount too small");
        require(amount <= self.max_purchase, "Amount too large");
        
        self.collected += amount;
        
        // Calculate tokens: amount * rate / 10^9 (since amount is in nanoTON)
        let tokens = (amount * self.rate) / 1000000000;
        
        // Distribute tokens
        self.distribute_tokens(tokens, context.sender);
        
        // Send funds to treasury
        self.send_to_treasury(amount);
    }

    inline fun distribute_tokens(tokens: Coins, to: Address) {
        // Mint tokens to buyer
        context.log("Distributing " + tokens.toString() + " tokens to " + to.toString());
        
        let msg = beginCell()
            .storeUint(0x00000001, 32) // internal transfer op
            .storeUint(0, 64) // query_id
            .storeCoins(tokens)
            .storeAddress(to)
        .endCell();
        
        self.token.send(SendParameters{
            to: self.token.address,
            value: toNano(0.05),
            body: msg
        });
    }

    inline fun send_to_treasury(amount: Coins) {
        // Send collected TON to treasury
        context.log("Sending " + amount.toString() + " to treasury");
        
        send(SendParameters{
            to: self.token.treasury,
            value: amount,
            body: null
        });
    }
}