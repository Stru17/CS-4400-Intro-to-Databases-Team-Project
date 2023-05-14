# Group 21's 4400 Final Project
This is Group 21's Phase 4 Project. Group 21 composes of Abhiram Bharatham, Carson Anderson, Sebastian Jankowski, Sean Ru, and Richard Zhang.

## Setup
### Prerequistes 
You must have the latest versions of these installed.
- Anaconda
- MySQL Community Server
- MySQL Workbench
- A modern webbrowser (Chrome, Opera, etc.)

### Virtual Environment Configuration
After installing the above technologies, you need to create a Anaconda virtual environment with Python version 3.9.15 environment. It MUST be version 3.9.15 for Python. Go to an Anaconda Prompt and run the following command to create this virtual environment:
```
conda create -n phase4 python=3.9.15
``` 
This creates the "phase4" virtual environment based on Python version 3.9.15. 

To get into this virtual environment, you can run the following command:
```
conda activate phase4
```
### Python Package Installation
In your "phase4" virtual environment, make sure that you are in the root directory of this project folder. Your command prompt should be in the same directory level as the `requirements.txt` file. Install the project's package for the virtual environment by running the following command:
```
pip install -r requirements.txt
```
This may take a while, so be patient.
### Database Integration
Make sure you have the latest version of MySQL installed. For the Flask server to connect with the database, you need to provide a password through a `.env` file. Create a new file in the root directory of this project folder (the project folder itself) called `.env` and put your MySQL server password in the file in the following format:
```
DB_PASSWORD = <your password here without quotes>
```
Make sure to save the file.
### Database Configuration
To setup the database with data and the stored procedures/views, run the following MySQL scripts located in the root directory of this project through MySQL Workbench. You must run `cs4400_database_v2 schema_and_data` before you can run `cs4400_phase3_stored_procedures_team96` first. The `cs4400_database_v2 schema_and_data` script creates the `restaurant_supply_express` database and populates it with data, while the `cs4400_phase3_stored_procedures_team96` script creates the stored procedures and views.

## Running
### Flask Server
It is recommended to run the Flask server first. Make sure that no other app is using port 5000. To run the Flask server, execute the following command in the "phase4" virtual environment to run the main Python script:
```
python app.py
```
The server is ready to go when you see the following printed on the console: 
```
 * Serving Flask app "app" (lazy loading)
 * Environment: production
   WARNING: This is a development server. Do not use it in a production deployment.
   Use a production WSGI server instead.
 * Debug mode: on
 * Restarting with stat
 * Debugger is active!
 * Debugger PIN: 220-905-786
 * Running on http://127.0.0.1:5000/ (Press CTRL+C to quit)
```
### Frontend
To run the frontend, make sure the Flask server is up. Then, open the `index.html` in this project folder with a modern web browser. You should see the Dashboard page that is connected to the Flask server. You can click on the navigation menu on the left to go to other pages.
### Development/Execution Tips
Here are some tips to fix for comman issues:
- If a request is taking too long (i.e. the tables are empty even with the Flask server up), the Flask server could be deadlocking. Close MySQL workbench and any other applications connected to the MySQL server and restart the Flask server.
- Reload the page if you made any HTML/CSS/Javascript changes. The LiveServer extension in VSCode make refresh for you whenever changes are made.
- If you make any changes to the MySQL scripts, you must run them to see the change take place. If these scripts are deadlocking, close the Flask server running (Ctrl + C).
## How the Project Works
The web browser renders HTML, CSS, and Javascript files that display the UI of the project. Bootstrap was used to quicken UI development. The Javascripts files are responsible for connecting the backend Flask server running on `localhost:5000` with the Frontend. Through HTTP, modules in Javascript make requests for data from the MySQL server and executing stored procedures. The Flask backend server (built in Python) take these requests from the Javascript in the frontend and executes certain queries to the MySQL server running on `localhost:3306` based on the request's route and payload. The Flask server then sends a HTTP response to the Frontend with the result of the query, and the Javascript changes the HTML and CSS of the webpage based on the HTTP response. 

For example, the Javascript may make a request for the `display_owner_view` data to the Flask server, in which the Flask server executes the `SELECT * FROM display_owner_vew` query. The Flask server takes the results from this query and sends the results in an HTTP response to the Javascript code, which would fill the HTML with the data from the query.

## Group Tasks
Here is how work was divided among Group 21:

Abhiram 
- Initial Flask Setup
- MySQL Integration
- Dashboard Tables Design

Richard
- Frontend to Flask Integration
- MySQL Integration and Flask API Design
- Input Validation
- Application Architecture Design

Sean
- Frontend Views and Modal Design
- Frontend to Flask Integration
- Input Validation

Carson
- Frontend Views and Modal Design
- Frontend to Flask Integration
- Frontend Cleanup and Revision

Sebastian
- Flask API Design
- Flask API Implementation
- QA/Testing
