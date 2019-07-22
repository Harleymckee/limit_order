# test('builds specified books', done => {
#   nock(EXCHANGE_API_URL)
#     .get('/products/BTC-USD/book?level=3')
#     .reply(200, {
#       asks: [],
#       bids: [],
#     });

#   nock(EXCHANGE_API_URL)
#     .get('/products/ETH-USD/book?level=3')
#     .reply(200, {
#       asks: [],
#       bids: [],
#     });

#   const server = testserver(port, () => {
#     const orderbookSync = new CoinbasePro.OrderbookSync(
#       ['BTC-USD', 'ETH-USD'],
#       EXCHANGE_API_URL,
#       'ws://localhost:' + port
#     );

#     orderbookSync.on('message', data => {
#       const state = orderbookSync.books[data.product_id].state();
#       assert.deepEqual(state, { asks: [], bids: [] });
#       assert.equal(orderbookSync.books['ETH-BTC'], undefined);
#     });
#   });

#   server.on('connection', socket => {
#     socket.send(JSON.stringify({ product_id: 'BTC-USD' }));
#     socket.send(JSON.stringify({ product_id: 'ETH-USD' }));
#     socket.on('message', () => {
#       server.close();
#       done();
#     });
#   });
# });
