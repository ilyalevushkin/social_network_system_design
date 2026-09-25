// Use DBML to define your database structure
// Docs: https://dbml.dbdiagram.io/docs

Table follows {
  following_user_id integer [not null]
  followed_user_id integer [not null]
  created_at timestamp
}

Table users {
  id integer [primary key]
  created_at timestamp
}

Table rates {
  rating_post_id integer [not null]
  rated_user_id integer [not null]
  created_at timestamp
}

Enum post_status {
  draft
  published
  deleted
}

Table posts {
  id integer [primary key]
  text text [note: 'Content of the post']
  author_id integer [not null]
  status post_status [not null]
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp
  place_id integer [not null]
  img_urls text[]
  rating integer
  comments_count integer
}


Table places {
  id integer [primary key]
  created_at timestamp
}

Table comments {
  id integer [primary key]
  text text [note: 'Content of the comment']
  post_id integer [not null]
  created_at timestamp
  index integer [note: 'unique incremented index']
}

Ref user_posts: posts.author_id ?> users.id // many-to-one

Ref: rates.rated_user_id ?> users.id
Ref: rates.rating_post_id ?> posts.id

Ref: users.id <? follows.following_user_id
Ref: users.id <? follows.followed_user_id

Ref: places.id <? posts.place_id

Ref: posts.id <? comments.post_id