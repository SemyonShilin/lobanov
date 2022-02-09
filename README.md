# Lobanov

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/lobanov`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lobanov'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lobanov

## Usage

### Схема хранения

Вообще схемы хранения могут быть разные, но начнём с одной.

Пусть есть ресурс и вложенный ресурс, например пусть Фрукты и Отзывы на фрукты

И пусть ещё всё это в неймспейсе `wapi/`

API подразумевается json.

- GET /fruits (index)
- GET /fruits/:id (show)
- POST /fruits (create)
- PUT /fruits/:id (update)
- DELETE /fruits/:id (destroy)

- GET /fruits/:id/reviews (index)
- POST /fruits/:id/reviews (create)
- GET /fruits/:id/reviews/:review_id (show)
- PUT /fruits/:id/reviews/:review_id (update)
- DELETE /fruits/:id/reviews/:review_id (destroy)

И может быть ещё что-то не по REST'у

- POST /fruits/:id/reviews/:review_id/upvote
- POST /fruits/:id/reviews/:review_id/downvote

При этом надо учесть, что один и тот же эндпоинт может возвращать ответы с разными статусами.

Как это всё будет храниться в нашей схеме

api-backend-specification

По идее внутри файла с описание path лежат разные HTTP statuses и verbs

Кажется единственный простой и понятный вариант - всегда называть сам файл path.yaml, а класть его в соответствии собственно с путём. Иначе возникают special-cases типа index.yaml / root.yaml - в зависимости от того, есть ли что-то внутри папки, или нет

index.yaml

```yaml
paths:
  "/fruits": # Здесь нужно совместить GET index и POST create
    "$ref": "./paths/fruits/path.yaml"
  "/fruits/{id}": # Здесь нужно как-то совместить GET show и DELETE destroy и PUT update
    "$ref": "./paths/fruits/[id]/path.yaml"
  "/fruits/{id}/reviews": # GET, POST
    "$ref": "./paths/fruits/[id]/reviews/path.yaml"
  "/fruits/{id}/reviews/{review_id}": # GET, PUT, DELETE
    "$ref": "./paths/fruits/[id]/reviews/[review_id]/path.yaml"
  "/fruits/{id}/reviews/{review_id}/upvote":
    "$ref": "./paths/fruits/[id]/reviews/[review_id]/upvote/path.yaml"
  "/fruits/{id}/reviews/{review_id}/downvote":
    "$ref": "./paths/fruits/[id]/reviews/[review_id]/downvote/path.yaml"
```

Внутри `paths/fruits/[id]/reviews/path.yaml`

Тут в принципе всё понятно, надо продумать

- как хранить компоненты
- как возвращать ошибки (ApiErrorResponse?)

Компоненты

```yaml
# успешные ответы сохраняем в components/responses
# формируем название как ResourсeNestedActionResponse.yaml
# Action - это название action'a контроллера, который обрабатывает запрос
- ./components/responses/FruitsIndexResponse.yaml
- ./components/responses/FruitsShowResponse.yaml
- ./components/responses/FruitsCreateResponse.yaml
- ./components/responses/FruitsReviewsDownvoteResponse.yaml

```

Это responses - это база, которую понятно как полностью автоматизировать и на которой мы будем дальше строить.

Для любых неуспешных ответов будем возвращать класс ErrorResponse.yaml (error_code, message, payload)

```yaml
- ./components/shared/ErrorResponse.yaml
- ./components/models/FruitModel.yaml # здесь то что возвращает FruitsShow и FruitsIndex
- ./components/params/PaginationParams.yaml # здесь например общие повторящиеся описания параметров типа пагинации
```

Что делать с тем, что index по идее возвращает массив моделей из Show?
Если это реально будет соблюдаться, можно сделать генерацию моделей и подстановку в постпроцессинге.

Но сейчас это не всегда так на самом деле.
В индексе может быть, например, объект, где одно поле items, а другие например про пагинацию или какие-то доп поля.

Если у нас будет какое-то соглашение, то можно будет тоже это как-то автоматизировать, завернуть во что-то типа IndexWithPagination. Но наверно лучше привести к тому, чтобы index возвращал только коллекцию.



```yaml
get:
  summary: Get fruit reviews
  responses:
    200:
      description: OK
      content:
        application/json:
          schema:
            "$ref": "../../../components/Fruits/item.yaml"
put:
  summary: Edit deal
  parameters:
    - in: path
      name: id
      schema:
        type: string
      required: true
      example: "1"
  responses:
    200:
      description: OK
      content:
        application/json:
          schema:
            "$ref": "../../../components/Deals/Update/200.yaml"
    422:
      description: Unprocessable Entity
      content:
        application/json:
          schema:
            "$ref": "../../../components/Deals/Update/422.yaml"


```




### Configuration

В config/initializers/lobanov.rb

```ruby
Lobanov.configure do |config|
  config.namespaces_to_ignore = ['wapi']
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/lobanov.
