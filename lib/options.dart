const options = {
  "name": "List Create Shops Api",
  "description": "",
  "renders": ["application/json", "text/html"],
  "parses": [
    "application/json",
    "application/x-www-form-urlencoded",
    "multipart/form-data"
  ],
  "actions": {
    "POST": {
      "username": {
        "type": "string",
        "required": false,
        "read_only": false,
        "label": "Username",
        "max_length": 45,
        "placeholder": "School emis Code / Phone number"
      },
      "password": {
        "type": "string",
        "required": false,
        "read_only": false,
        "label": "Password",
        "obscure": true,
        "max_length": 25
      }
    }
  }
};
