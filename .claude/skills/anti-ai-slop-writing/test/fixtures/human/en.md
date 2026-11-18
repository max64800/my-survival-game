The RPC endpoint died at 3am on a Tuesday. I know because my phone buzzed, and I made the mistake of looking at it.

What actually broke: our indexer assumed block timestamps arrive in order. They usually do. Then Solana reorged twice in ninety seconds and the indexer wrote a block from the future, which meant every downstream balance query returned a number that was correct for a chain nobody was on anymore. Took me until 6am to see it, mostly because I was looking at the query layer and the bug was four services upstream.

We shipped a fix that afternoon: reject any block whose timestamp is more than 30 seconds ahead of the previous one, log it, move on. Crude. It has caught eleven bad blocks since March and zero good ones, so I have stopped feeling bad about it.
