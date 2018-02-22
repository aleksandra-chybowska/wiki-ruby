require 'sinatra'
require 'sinatra/activerecord'
require 'fileutils'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => 'wiki.db'
  )

class User < ActiveRecord::Base
  validates :username, presence: true, uniqueness: true
  validates :password, presence: true
end

@info = ""
$credentials = ['','']
$backgroundcolor=""

#universal function to read files
def readFile(filename)
  info = ""
  file = File.open(filename)
  
  file.each do |line|
    info = info + line
  end

  file.close
  return info
end

#readFile that addes <br> at the end of each line
def readFileLog(filename)
  info = ""
  file = File.open(filename)
  
  file.each do |line|
    info = info + line + '<br>'
  end

  file.close
  return info
end

#function that updates log file log.txt
def updateLog(username,type)
  date = Time.now.strftime("%d-%m-%Y--%H:%M")
  filenamee="#{date}-#{username}"
  info = "#{date}, #{username}: Wiki content updated,#{type},Link to file:/showlogbackup/#{filenamee}.txt"
  file = File.open("log.txt", "a")
  file.puts info
  file.close
end

#copy content of inputFile to outputFile
def copyFileContents(inputFile, outputFile)
  inputFileHandler = File.open(inputFile, 'r')
  outputFileHandler = File.open(outputFile, 'w')

  IO.copy_stream(inputFileHandler, outputFileHandler)

  inputFileHandler.close
  outputFileHandler.close
end

#add a backup
def backupz(username)
    date = Time.now.strftime("%d-%m-%Y--%H:%M")
    name="#{date}-#{username}"
    filname="backups/#{name}.txt"

    copyFileContents('wiki.txt', filname)
end

#check if the connection is authorised
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

#run if your function should be available for logged in users
def protected!
  if authorized?
    return
  end
  redirect '/denied'
end

#protected! function restricted to admin-only access
def protected_admin!
  if $credentials != nil && $credentials[0].to_s == 'Admin'
    return
  end
  redirect '/denied'
end


get '/' do
  @info  = readFile("wiki.txt").chomp
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

#edit wiki and save its content to backup
put '/edit' do
  protected!
  info = "#{params[:message]}"
  @info = info
  file = File.open("wiki.txt", "w")
  file.puts @info
  file.close

  updateLog($credentials[0],"Amended")
  backupz($credentials[0])
  redirect '/'
end

get '/admincontrols' do
  protected_admin!
  @list2 = User.all.sort_by { |u| [u.id] }
  erb :admincontrols
end

get '/archive' do
  protected_admin!
  dirr = "backups"
  #list files within directory omitting . and ..
  @list3 = Dir.entries(dirr) - %w[. ..]
  erb :archive
end

get '/showlog' do
  @log  = readFileLog("log.txt").chomp  
  erb :showlog
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

#show content of a backup
get '/showlogbackup/:logzbackup' do
    protected!
    info =""
    filname="backups/#{params[:logzbackup]}"
    file=File.open(File.absolute_path(filname),'r')
    file.each do |line|
        info = info + line
    end
    file.close
    @log=info
    erb :backup
end

#reset to a certain backup
post '/resettoversion' do
  protected!
  versionname=params[:filename]
  filename="backups/#{versionname}"
  copyFileContents(filename, 'wiki.txt')
  redirect '/admincontrols'
end
  
get '/resetwiki' do
  protected!
  copyFileContents('original.txt', 'wiki.txt')
  updateLog($credentials[0],"Reset")
  redirect '/archive'
end

#delete a backup
post '/deleteversion' do
  protected!
  versionname=params[:filename]
  filename="backups/#{versionname}"
  File.delete(filename)
  redirect '/admincontrols'
end

get '/adminbackup' do
  protected!
  backupz($credentials[0])
  redirect '/admincontrols'
end

#group of functions that change background
get '/bluebackground' do
  $backgroundcolor="007996"
  redirect '/'
end
get '/greenbackground' do
  $backgroundcolor="668d3c"
  redirect '/'
end

get '/orangebackground' do
  $backgroundcolor="ff8642"
  redirect '/'
end

get '/redbackground' do
  $backgroundcolor="c0362c"
  redirect '/'
end
get '/defbackground' do
  $backgroundcolor="17A2B8"
  redirect '/'
end

not_found do 
  status 404
  erb :notfound
end