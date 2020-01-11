// all books, all categories
db.category.find({}, { name: 1 }).pretty();

// all books, one category
db.books.find({ categories: ObjectId("58b603b1ef9f298bd0253972") }, { shortDescription: 0, longDescription: 0, publisher: 0, authors: 0 }).pretty();

// details for one book, multiple join with collections "authors", "category", "publisher".
// selects the fields with a stage "project" at the end
db.books.aggregate([
    { 
        $match: 
        { 
            "_id": 2 
        } 
    },
    {
        $lookup:
        {
            from: "authors",
            localField: "authors",
            foreignField: "_id",
            as: "authors"
        }
    },
    {
        $lookup:
        {
            from: "category",
            localField: "categories",
            foreignField: "_id",
            as: "categories"
        }
    },
    {
        $lookup:
        {
            from: 'publisher',
            localField: 'publisher',
            foreignField: '_id',
            as: 'publisher'
        }
    },
    {
        $project: {
            "_id": 1,
            "title": 1,
            "publishedDate": 1,
            "thumbnailUrl": 1,
            "authors": 1,
            "categories": 1,
            "publishers": 1,
            "Category": "$categories.name",
            "Publisher": "$publisher.name"
        }
    }
]).pretty();


