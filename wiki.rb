require 'sinatra'
require 'sinatra/activerecord'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => 'wiki.db'
  )

class User < ActiveRecord::Base
  validates :username, presence: true, uniqueness: true
  validates :password, presence: true
end

$myinfo = "Aleksandra Chybowska"
@info = ""
$credentials = ['','']

def readFile(filename)
  info = ""
  file = File.open(filename)
  
  file.each do |line|
    info = info + line
  end

  file.close
  return info
end


def authorized?
  if $credentials != nil
    @Userz = User.where(:username => $credentials[0]).to_a.first
    if @Userz
      if @Userz.edit == true
        return true
      else
        return false
      end
    else
     return false
   end
 end
end

def protected!
  if authorized?
    return
  end
  redirect '/denied'
end

def protected_admin!
  if $credentials != nil && $credentials[0].to_s == 'Admin'
    return
  end
  redirect '/denied'
end

def reverse (string)
 string.each_char.to_a.reverse.join
end


get '/' do
  @info  = readFile("wiki.txt").chomp
  len = @info.length 
  @words = len.to_s

  erb :home
end

get '/about' do
  erb :about
end

get '/register' do
  erb :register
end

post '/register' do
  n = User.new   
  n.username = params[:username]
  n.password = params[:password]    

  if n.username == "Admin" and n.password == "Password"
    n.edit = true 
  end

  n.save    
  redirect "/"
end

get '/logout' do
  $credentials = ['','']
  redirect '/'
end

get '/login' do
  erb :login
end


post '/login' do
  $credentials = [params[:username],params[:password]]
  @Users = User.where(:username => $credentials[0]).to_a.first

  if @Users && @Users.password == $credentials[1]
    redirect '/'
  else
    $credentials = ['','']
    redirect '/wrongaccount'
  end
end


get '/wrongaccount' do
  erb :wrongaccount
end

get '/edit' do
  protected!
  info =""
  file=File.open("wiki.txt")
  file.each do |line|
    info = info + line
  end

  file.close
  @info=info
  erb :edit
end


put '/edit' do
  info = "#{params[:message]}"
  @info = info
  file = File.open("wiki.txt", "w")
  file.puts @info
  file.close
  redirect '/'
end

get '/admincontrols' do
  protected_admin!
  @list2 = User.all.sort_by { |u| [u.id] }
  erb :admincontrols
end

get '/denied' do
  erb :denied
end

put '/user/:uzer' do
  protected_admin!
  n = User.where(:username => params[:uzer]).to_a.first
  n.edit = params[:edit] ? 1 : 0
  n.save
  redirect '/'
end

get '/user/delete/:uzer' do
  protected_admin!
  n = User.where(:username => params[:uzer]).to_a.first
  if n.username == "Admin"
    erb :denied
  else
    n.destroy
    redirect '/admincontrols'
  end
end


get '/reverse' do
  $myinfo = reverse($myinfo)
  redirect '/'
end

not_found do 
  status 404
  erb :notfound
end
