db;
db.products.remove({});
db.products.insertMany([
	{name: 'Prod1', category: 'Cat1', price: 10.2, count:80},
	{name: 'Prod2', category: 'Cat2', price: 5.3, count:100},
	{name: 'Prod3', category: 'Cat1', price: 20.7, count:40},
	{name: 'Prod4', category: 'Cat2', price: 15.0, count:50},
	
]);
db.products.find();
db.products.aggregate(
	{$group:
		{ _id: '$category', 
		total: { $sum: {$multiply: ['$price', '$count']} } 
		}
	});
	
db.products.remove({name:'Prod3'});
db.products.find();
db.products.find().sort({price: -1}).limit(2)