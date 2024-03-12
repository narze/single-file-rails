# 1. Gems (Inline)
require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'

  gem 'rails', '~> 7.1'
  gem 'sqlite3'
end

# 2. Rails App & Routes
require 'rails/all'

class App < Rails::Application
  config.root = __dir__
  config.consider_all_requests_local = true
  config.secret_key_base = 'i_am_a_secret'
  # config.active_storage.service_configurations = { 'local' => { 'service' => 'Disk', 'root' => './storage' } }

  routes.append do
    root to: 'posts#index'

    resources :posts do
      resources :comments
    end
  end
end

# 3. Database
database = 'db/development.sqlite3'
ENV['DATABASE_URL'] = "sqlite3:#{database}"
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: database)
ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Schema.define do
  unless ActiveRecord::Base.connection.table_exists?(:posts)
    create_table :posts, force: true do |t|
      t.string :title
    end

    create_table :comments, force: true do |t|
      t.integer :post_id
      t.string :body
    end
  end
end

# 4. Models
# class ApplicationRecord < ActiveRecord::Base
#   primary_abstract_class
# end

class Post < ActiveRecord::Base
  has_many :comments
end

class Comment < ActiveRecord::Base
  belongs_to :post
end

# 5. Controllers
class ApplicationController < ActionController::Base
  include Rails.application.routes.url_helpers
end

class PostsController < ApplicationController
  def index
    @post = Post.new

    render inline: <<~HTML
      <h1>Welcome to Rails in Single File!</h1>

      <% if flash[:notice] %>
        <p style="color: red"><%= flash[:notice] %></p>
      <% end %>

      <h2>Posts</h2>

      <ul>
        <% Post.all.each do |post| %>
          <li><%= link_to post.title, post_path(post) %></li>
        <% end %>
      </ul>

      <hr>

      <h2>Add new post</h2>

      <%= form_for(@post) do |form| %>
        <%= form.text_field :title, placeholder: "Post Title" %>

        <%= form.submit "Create Post" %>
      <% end %>
    HTML
  end

  def create
    @post = Post.create!(params.permit![:post])
    redirect_to root_path, notice: "Post ##{@post.id} created!"
  end

  def show
    @post = Post.find(params[:id])

    render inline: <<~HTML
      <h1>Post ##{@post.id}</h1>

      <h2>#{@post.title}</h2>

      <% if flash[:notice] %>
        <p style="color: red"><%= flash[:notice] %></p>
      <% end %>

      <p>Comments</p>

      <ul>
        <% @post.comments.each do |comment| %>
          <li>
            <%= comment.body %> <%= button_to "x", post_comment_path(@post, comment), method: :delete, form: { style: "display: inline-block;" } %>
          </li>
        <% end %>
      </ul>

      <%= form_for([@post, Comment.new]) do |form| %>
        <%= form.text_field :body, placeholder: "Comment Body" %>
        <%= form.submit "Add Comment" %>
      <% end %>

      <%= button_to "Delete", post_path(@post), method: :delete %>
      <%= link_to "Back", root_path %>
    HTML
  end

  def destroy
    @post = Post.find(params[:id]).destroy

    redirect_to root_path, notice: "Post ##{@post.id} deleted!"
  end
end

class CommentsController < ApplicationController
  def create
    @post = Post.find(params[:post_id])
    @comment = @post.comments.create!(params.permit![:comment])
    redirect_to post_path(@post), notice: "Comment ##{@comment.id} created!"
  end

  def destroy
    @post = Post.find(params[:post_id])
    @comment = @post.comments.find(params[:id]).destroy
    redirect_to post_path(@post), notice: "Comment ##{@comment.id} deleted!"
  end
end

App.initialize!

run App
