export const fund = async (address) => {
    const res = await (await fetch('http://127.0.0.1:9123/gas', {
        method: 'POST',
        body: JSON.stringify({
            "FixedAmountRequest": {
                "recipient": address
            }
        }),
        headers: {
            'Content-Type': 'application/json'
        }
    })).json()
    console.log(res.error == null ? 'Successfully funded account' : 'error funding account');
}