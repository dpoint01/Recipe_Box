require 'sinatra'
require 'haml'
require 'pg'


#----------------DATABASE CONNEC----------------#

def connect_db
  begin
    connection = PG.connect(dbname: 'recipes')
    yield(connection)
  ensure
    connection.close
  end
end

#-----------------------HOME-----------------------#
get '/' do
  redirect '/recipes'
end

#------------------LIST OF RECIPES-----------------#
get '/recipes' do
  @page = params[:page] || 1
  @page = @page.to_i
  @search = params[:query]
  offset = ((@page - 1) * 20)
    if !@search
      query = "SELECT recipes.name, recipes.id FROM recipes ORDER BY recipes.name
               LIMIT 30 OFFSET #{offset};"
      @all_recipes = connect_db {|conn| conn.exec(query)}.to_a
    end
    if @search
      query = "SELECT recipes.name, recipes.id FROM recipes WHERE recipes.name ILIKE $1
               ORDER BY recipes.name;"
      @all_recipes = connect_db {|conn| conn.exec_params(query, ["%#{@search}%"])}
    end
  haml :'index'
end

#--------------------RECIPE INFO-----------------#
get '/recipes/:id' do
  recipe_id = params[:id]
  query = "SELECT recipes.name, recipes.instructions, recipes.description FROM recipes
           WHERE recipes.id = $1;"
  @recipe_info = connect_db {|conn| conn.exec_params(query, [recipe_id])}.to_a
  query2 = "SELECT ingredients.name FROM recipes
            JOIN ingredients ON recipes.id = ingredients.recipe_id
            WHERE ingredients.recipe_id = $1"
  @ingredients = connect_db {|conn| conn.exec_params(query2, [recipe_id])}.to_a
  haml :'show'
end
