## Tech specs

Sui repo where you can download everything:
[https://github.com/MystenLabs/sui]

<ul>
    <li>Sui bin v0.27.1-157ac7203 (installed from devnet branch)</li>
    <li>Sui test validator (installed from devnet branch)</li>
    <li>Sui TS sdk v0.28.0</li>
    <li>Frontend: Angular (-v TBD)</li>
    <li>Backend: Nest.js v9.0</li>
</ul>

## SUI games contracts module

In this repo you can read all contracts that we used to develop Indelve on-chain games module

Games that we will develop:

<ul>
    <li>memotest WIP</li>
    <li>fridays trivia (from Trantorian)</li>
    <li>hangman</li>
    <li>tic tac toe</li>
    <li>And much more soon...</li>
</ul>

## /run folder

there you can find some implementations on how to use contracts for playing the game
to run this examples, please first setup your local sui network.
Once you have your local network working, execute the following commands:

<ol>
    <li>from root folder of this repo ~> `cd run`</li>
    <li>`npm i`</li>
    <li>`node index.js`</li>
</ol>

index will run an example of a play using the default accounts previously set up in config.js
Note that you MUST change this accounts in order to run this example in your own network. I have created this accounts in my local env and only exists for me. Of course you can use the private keys and update the sui.keystore to use the same accounts as me as well. Feel free to use any accounts you want for this example.
