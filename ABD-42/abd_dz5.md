# Какие команды отвечают за:  
- сохранение результата в текстовый файл (это Action или Transformation?);  
	- saveAsTextFile
	- Action
- получение первых n-элементов массива (Action или Transformation?);  
	- take(n)
	- Action
- объединение двух RDD в один (Action или Transformation?); 
	- join
	- Transformation
- в чем разница между Reduce и CoGroup-операторами (Action или Transformation?).
	- reduce схлопывает RDD в скаляр по заданным правилам
	- cogroup берет все ключи из двух RDD и сохраняет их в новый RDD, состоящий из всех ключей и кортежа, содержащего значения по этому ключу из обоих исходных RDD
# Нарисуйте DAG для Spark для подсчёта количества уникальных слов в файле.

Не разобрался как рисовать DAG. Надеюсь подойдет в качестве решения.
Буду благодарен за комментарии по коду, мне кажется он не самый оптимальный.

```python
sp = (
    SparkSession.builder
        .master("local")
        .appName("Word Count")
        .getOrCreate()
)
sc = sp.sparkContext

words = sc.textFile('war_and_peace.ru.txt')
(words
    .flatMap(lambda x: x.split())
    .map(lambda x: (
        ''.join(
            filter(
                str.isalpha, x
                )
            )
        , 1)
    )
    .filter(lambda x: x[0]!='')
    .reduceByKey(add)
    .sortBy(lambda x: x[1], False)
    .collect()
)
```

