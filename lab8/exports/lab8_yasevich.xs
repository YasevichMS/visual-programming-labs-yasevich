workspace "lab8-Yasevich" {
  acceptance = {ai_terms: true}
  preferences = {
    internal_docs    : false
    track_performance: true
    sql_names        : false
    sql_columns      : true
  }
}
---
table categories {
  auth = false

  schema {
    int id
    timestamp created_at?=now {
      visibility = "private"
    }
  
    text name filters=trim
    text description? filters=trim
    bool is_active?=true
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}
---
table users {
  auth = false

  schema {
    int id
    timestamp created_at?=now {
      visibility = "private"
    }
  
    text full_name filters=trim
    text student_id filters=trim
    text email filters=trim
    text phone? filters=trim
    enum role? {
      values = ["student", "staff", "admin"]
    }
  
    bool is_active?=true
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}
---
table equipment {
  auth = false

  schema {
    int id
    timestamp created_at?=now {
      visibility = "private"
    }
  
    text name filters=trim
    int categories_id? {
      table = "categories"
    }
  
    text inventory_number filters=trim
    enum condition? {
      values = ["new", "good", "worn", "broken"]
    }
  
    decimal daily_price
    bool is_available?=true
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}
---
table rentals {
  auth = false

  schema {
    int id
    timestamp created_at?=now {
      visibility = "private"
    }
  
    int users_id? {
      table = "users"
    }
  
    int equipment_id? {
      table = "equipment"
    }
  
    timestamp? start_date
    timestamp? end_date
    decimal total_price?
    enum status? {
      values = ["pending", "active", "completed", "cancelled"]
    }
  
    text cancelled? filters=trim
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}
---
// Creates a record in the event log table
function "Quick Start/log_event" {
  input {
    // Unique identifier for the user who performed the action.
    int user_id
  
    // A description of the action performed by the user (e.g., 'login', 'created_invoice').
    text action
  
    // Additional data related to the event, such as resource IDs or old/new values.
    json metadata?
  }

  stack {
    // Add a new user event log entry
    db.add "" {
      data = {
        created_at: "now"
        user_id   : $input.user_id
        action    : $input.action
        metadata  : $input.metadata
      }
    } as $new_log_entry
  }

  response = null
  tags = ["xano:quick-start"]
}
---
// This function generates a magic token with a 60 minute expiration date.
function "Quick Start/generate_magic_link" {
  input {
    email email?
  }

  stack {
    // Checks that the email input is not empty
    precondition ($input.email != null) {
      error = "email is required but was not suppiled. "
    }
  
    // Gets the user record by email
    db.query "" {
      where = $db.user.email == $input.email
      return = {type: "single"}
    } as $user
  
    // Verifies that the user record exists
    precondition ($user != null) {
      error_type = "notfound"
      error = "No user found for that email."
    }
  
    // Creates a unique UUID as token
    security.create_uuid as $token
  
    // Builds the password reset object
    var $password_reset {
      value = {}
        |set:"token":$token
        |set:"expiration":(now
          |add_secs_to_timestamp:(3600|to_int)
        )
        |set:"used":false
    }
  
    // Updates the user record with the password reset object
    db.edit "" {
      field_name = "id"
      field_value = $user|get:"id":0
      data = {password_reset: $password_reset}
    } as $updated_password_reset
  }

  response = {token: $token, email: $updated_password_reset.email}
  tags = ["xano:quick-start"]
}
---
// Checks that a user has the appropriate role level. This example sets a hierarchy of roles, and a user must pass the minimum level to execute.
function "Quick Start/enforce_role" {
  input {
    // The ID of the user to check the role for.
    int user_id
  
    // The role required to perform the action.
    text required_role
  }

  stack {
    // Defines a hierarchy of roles with numerical levels.
    var $role_hierarchy {
      value = {admin: 2, member: 1}
    }
  
    // Retrieve the user's role from the database.
    db.get "" {
      field_name = "id"
      field_value = $input.user_id
      output = ["role"]
    } as $user
  
    // Ensure the user exists
    precondition ($user != null) {
      error_type = "inputerror"
      error = "User not found with the provided ID."
    }
  
    // Extract the user's role from the retrieved user data.
    var $user_role {
      value = $user.role
    }
  
    // Get the numerical level of the user's role. Defaults to 0 if not defined.
    var $user_role_level {
      value = $role_hierarchy|get:$user_role
    }
  
    // Get the numerical level of the required role. Defaults to 0 if not defined.
    var $required_role_level {
      value = $role_hierarchy|get:$input.required_role
    }
  
    // Ensure the required role is a valid, defined role in the hierarchy.
    precondition ($required_role_level > 0) {
      error_type = "inputerror"
      error = "Invalid required role specified: " ~ $input.required_role
    }
  
    // Check if the user's role level is sufficient for the required role.
    conditional {
      if ($user_role_level < $required_role_level) {
        throw {
          name = "accessdenied"
          value = "User does not have the required role to perform this action. Required: " ~ $input.required_role ~ ", Actual: " ~ $user_role
        }
      }
    }
  }

  response = null
  tags = ["xano:quick-start"]
}
---
// This group provides endpoints for user login, signup, and reset password, returning authentication tokens and user records.
api_group Authentication {
  canonical = "7DkVEZ29"
  swagger = {active: false}
  tags = ["xano:quick-start"]
}
---
// Contains API Endpoints for reports of event logs
api_group "Event Logs" {
  canonical = "xfHUq_Z2"
  swagger = {active: false}
  tags = ["xano:quick-start"]
}
---
api_group "lab8-api" {
  canonical = "cOpF7qlg"
}
---
// Login and retrieve an authentication token
query "auth/login" verb=POST {
  api_group = "Authentication"

  input {
    email email? filters=trim|lower
    text password?
  }

  stack {
    // Get the user record via email
    db.get "" {
      field_name = "email"
      field_value = $input.email
      output = ["id", "created_at", "name", "email", "password", "role"]
    } as $user
  
    // Check to make sure a user with that email exists
    precondition ($user != null) {
      error_type = "accessdenied"
      error = "Invalid Credentials."
    }
  
    // Check that the password matches the hashed password
    security.check_password {
      text_password = $input.password
      hash_password = $user.password
    } as $pass_result
  
    // Verify that the password check passed
    precondition ($pass_result) {
      error_type = "accessdenied"
      error = "Invalid Credentials."
    }
  
    // Create an authentication token
    security.create_auth_token {
      table = ""
      extras = {}
      expiration = 86400
      id = $user.id
    } as $authToken
  
    // Create an event log for login
    function.run "Quick Start/log_event" {
      input = {user_id: $user.id, action: "login", metadata: $user}
    } as $event_log
  }

  response = {authToken: $authToken, user_id: $user.id}
  tags = ["xano:quick-start"]
}
---
// Get the user record belonging to the authentication token
query "auth/me" verb=GET {
  api_group = "Authentication"
  auth = ""

  input {
  }

  stack {
    // Get the user record based on the auth ID
    db.get "" {
      field_name = "id"
      field_value = $auth.id
      output = ["id", "created_at", "name", "email", "role"]
    } as $user
  
    // Create an event log for get user record
    function.run "Quick Start/log_event" {
      input = {
        user_id : $user.id
        action  : "get_auth_user"
        metadata: $user
      }
    } as $event_log
  }

  response = $user
  tags = ["xano:quick-start"]
}
---
// Signup and retrieve an authentication token
query "auth/signup" verb=POST {
  api_group = "Authentication"

  input {
    text name?
    email email? filters=trim|lower
    text password?
  }

  stack {
    // Check if a user record with that email exists
    db.get "" {
      field_name = "email"
      field_value = $input.email
    } as $user
  
    // Verify that the email being used to sign up is unique
    precondition ($user == null) {
      error_type = "accessdenied"
      error = "An account with this email already exists."
    }
  
    // Create a new user record
    db.add "" {
      data = {
        created_at: "now"
        name      : $input.name
        email     : $input.email
        password  : $input.password
        role      : "member"
      }
    } as $user
  
    // Create an authentiction token
    security.create_auth_token {
      table = ""
      extras = {}
      expiration = 86400
      id = $user.id
    } as $authToken
  
    // Create an event log for signup
    function.run "Quick Start/log_event" {
      input = {user_id: $user.id, action: "signup", metadata: $user}
    } as $event_log
  }

  response = {authToken: $authToken, user_id: $user.id}
  tags = ["xano:quick-start"]
}
---
// Query all categories records
query categories verb=GET {
  api_group = "Authentication"

  input {
  }

  stack {
    db.query categories {
      return = {type: "list"}
    } as $categories
  }

  response = $categories
}
---
// Add categories record
query categories verb=POST {
  api_group = "Authentication"

  input {
    dblink {
      table = "categories"
    }
  }

  stack {
    db.add categories {
      enforce_hidden_fields = false
      data = {created_at: "now"}
    } as $categories
  }

  response = $categories
}
---
// Delete categories record.
query "categories/{categories_id}" verb=DELETE {
  api_group = "Authentication"

  input {
    int categories_id? filters=min:1
  }

  stack {
    db.del categories {
      field_name = "id"
      field_value = $input.categories_id
    }
  }

  response = null
}
---
// Get categories record
query "categories/{categories_id}" verb=GET {
  api_group = "Authentication"

  input {
    int categories_id? filters=min:1
  }

  stack {
    db.get categories {
      field_name = "id"
      field_value = $input.categories_id
    } as $categories
  
    precondition ($categories != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $categories
}
---
// Edit categories record
query "categories/{categories_id}" verb=PATCH {
  api_group = "Authentication"

  input {
    int categories_id? filters=min:1
    dblink {
      table = "categories"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch categories {
      field_name = "id"
      field_value = $input.categories_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $categories
  }

  response = $categories
}
---
// Query all equipment records
query equipment verb=GET {
  api_group = "Authentication"

  input {
  }

  stack {
    db.query equipment {
      return = {type: "list"}
    } as $equipment
  }

  response = $equipment
}
---
// Add equipment record
query equipment verb=POST {
  api_group = "Authentication"

  input {
    dblink {
      table = "equipment"
    }
  }

  stack {
    db.add equipment {
      enforce_hidden_fields = false
      data = {created_at: "now"}
    } as $equipment
  }

  response = $equipment
}
---
query equipment verb=GET {
  api_group = "lab8-api"

  input {
    int page?=1
    int per_page?=10
  }

  stack {
    db.query equipment {
      sort = {equipment.id: "asc"}
      return = {
        type  : "list"
        paging: {
          page    : $input.page
          per_page: $input.per_page
          totals  : true
        }
      }
    } as $model
  }

  response = $model
}
---
// Add equipment record
query equipment verb=POST {
  api_group = "lab8-api"

  input {
    dblink {
      table = "equipment"
    }
  }

  stack {
    db.add equipment {
      enforce_hidden_fields = false
      data = {
        created_at      : "now"
        name            : $input.name
        categories_id   : $input.categories_id
        inventory_number: $input.inventory_number
        condition       : $input.condition
        daily_price     : $input.daily_price
        is_available    : $input.is_available
      }
    } as $model
  }

  response = $model
}
---
// Delete equipment record.
query "equipment/{equipment_id}" verb=DELETE {
  api_group = "Authentication"

  input {
    int equipment_id? filters=min:1
  }

  stack {
    db.del equipment {
      field_name = "id"
      field_value = $input.equipment_id
    }
  }

  response = null
}
---
// Get equipment record
query "equipment/{equipment_id}" verb=GET {
  api_group = "Authentication"

  input {
    int equipment_id? filters=min:1
  }

  stack {
    db.get equipment {
      field_name = "id"
      field_value = $input.equipment_id
    } as $equipment
  
    precondition ($equipment != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $equipment
}
---
// Edit equipment record
query "equipment/{equipment_id}" verb=PATCH {
  api_group = "Authentication"

  input {
    int equipment_id? filters=min:1
    dblink {
      table = "equipment"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch equipment {
      field_name = "id"
      field_value = $input.equipment_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $equipment
  }

  response = $equipment
}
---
// Edit equipment record
query "equipment/{equipment_id}" verb=PATCH {
  api_group = "lab8-api"

  input {
    int equipment_id? filters=min:1
    dblink {
      table = "equipment"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch equipment {
      field_name = "id"
      field_value = $input.equipment_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $model
  }

  response = $model
}
---
// Get equipment record
query "equipment/{equipment_id}" verb=GET {
  api_group = "lab8-api"

  input {
    int equipment_id? filters=min:1
  }

  stack {
    db.get equipment {
      field_name = "id"
      field_value = $input.equipment_id
    } as $model
  
    precondition ($model != null) {
      error_type = "notfound"
      error = "Not Found"
    }
  }

  response = $model
}
---
// Delete equipment record
query "equipment/{equipment_id}" verb=DELETE {
  api_group = "lab8-api"

  input {
    int equipment_id? filters=min:1
  }

  stack {
    db.del equipment {
      field_name = "id"
      field_value = $input.equipment_id
    }
  }

  response = null
}
---
// Pull all event logs for the authenticated user
query "logs/user/my_events" verb=GET {
  api_group = "Event Logs"
  auth = ""

  input {
  }

  stack {
    // Retrieve event logs for the authenticated user
    db.query "" {
      where = $db.event_log.user_id == $auth.id
      return = {type: "list"}
    } as $user_events
  }

  response = $user_events
  tags = ["xano:quick-start"]
}
---
// Use this endpoint to send a welcome email to a user
query "message/send_welcome_email" verb=POST {
  api_group = "Authentication"

  input {
    // The ID of the user to send the welcome email to.
    int user_id
  }

  stack {
    // Retrieve the user record for the given user ID.
    db.get "" {
      field_name = "id"
      field_value = $input.user_id
    } as $user_record
  
    // Ensure the user record exists before proceeding.
    precondition ($user_record != null) {
      error_type = "notfound"
      error = "User not found."
    }
  
    // Set the subject line for the welcome email.
    var $email_subject {
      value = "Welcome to Our Service, " ~ $user_record.name ~ "!"
    }
  
    // Construct the HTML body of the welcome email.
    var $email_body {
      value = "<html><body><h1>Welcome, " ~ $user_record.name ~ "!</h1><p>Thank you for joining our service. We're excited to have you!</p><p>Best regards,<br>The Team</p></body></html>"
    }
  
    // Send welcome email
    util.send_email {
      service_provider = "xano"
      subject = $email_subject
      message = $email_body
    } as $send_email
  
    // Log welcome email sent for user
    function.run "Quick Start/log_event" {
      input = {
        user_id : $input.user_id
        action  : "welcome_email_sent"
        metadata: {}
      }
    } as $event_log
  }

  response = $send_email
  tags = ["xano:quick-start"]
}
---
// Query all rentals records
query rentals verb=GET {
  api_group = "Authentication"

  input {
  }

  stack {
    db.query rentals {
      return = {type: "list"}
    } as $rentals
  }

  response = $rentals
}
---
// Add rentals record
query rentals verb=POST {
  api_group = "Authentication"

  input {
    dblink {
      table = "rentals"
    }
  }

  stack {
    db.add rentals {
      enforce_hidden_fields = false
      data = {created_at: "now"}
    } as $rentals
  }

  response = $rentals
}
---
// Delete rentals record.
query "rentals/{rentals_id}" verb=DELETE {
  api_group = "Authentication"

  input {
    int rentals_id? filters=min:1
  }

  stack {
    db.del rentals {
      field_name = "id"
      field_value = $input.rentals_id
    }
  }

  response = null
}
---
// Get rentals record
query "rentals/{rentals_id}" verb=GET {
  api_group = "Authentication"

  input {
    int rentals_id? filters=min:1
  }

  stack {
    db.get rentals {
      field_name = "id"
      field_value = $input.rentals_id
    } as $rentals
  
    precondition ($rentals != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $rentals
}
---
// Edit rentals record
query "rentals/{rentals_id}" verb=PATCH {
  api_group = "Authentication"

  input {
    int rentals_id? filters=min:1
    dblink {
      table = "rentals"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch rentals {
      field_name = "id"
      field_value = $input.rentals_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $rentals
  }

  response = $rentals
}
---
// Exchanges magic token for auth token. Logs in user with the one-time link.
query "reset/magic-link-login" verb=POST {
  api_group = "Authentication"

  input {
    text magic_token? filters=trim
    text email? filters=trim
  }

  stack {
    // Check to make sure the magic token exists
    precondition ($input.magic_token != null) {
      error = "magic_token is required but was not provided."
    }
  
    // Check to make sure the email exists
    precondition ($input.email != null) {
      error = "email is required but not provided"
    }
  
    // Get the user record with the email from the URL
    db.get "" {
      field_name = "email"
      field_value = $input.email
      output = [
        "id"
        "created_at"
        "name"
        "email"
        "role"
        "password_reset.token"
        "password_reset.expiration"
        "password_reset.used"
      ]
    } as $user
  
    // Validate the UUID matches the hashed value
    security.check_password {
      text_password = $input.magic_token
      hash_password = $user.password_reset.token
    } as $verify_token
  
    // Verify the UUID validation is true
    precondition ($verify_token) {
      error_type = "unauthorized"
      error = "The token did not match"
    }
  
    // Check that the password reset token has not expired
    precondition ($user.password_reset.expiration > now) {
      error = "Magic token has expired. Please request another one."
    }
  
    // Check to make sure the password reset has not been used
    precondition ($user.password_reset.used == false) {
      error = "This magic link has already been used. Please request another one."
    }
  
    // Create an authentication token
    security.create_auth_token {
      table = ""
      extras = ""
      expiration = 86400
      id = $user.id
    } as $auth_token
  
    // Update the user record that the password reset token has been used
    db.edit "" {
      field_name = "id"
      field_value = $user.id
      data = {
        password_reset: {
        token     : $user.password_reset.token
        expiration: $user.password_reset.expiration
        used      : true
      }
      }
    } as $user1
  
    // Create an event log for password reset login
    function.run "Quick Start/log_event" {
      input = {
        user_id : $user.id
        action  : "login_for_password_reset"
        metadata: $user1
      }
    } as $event_log
  }

  response = {authToken: $auth_token, user_id: $user1.id}
  tags = ["xano:quick-start"]
}
---
// Request a one-time magic link to reset password
query "reset/request-reset-link" verb=GET {
  api_group = "Authentication"

  input {
    email email?
  }

  stack {
    // Generate a one-time magic link
    function.run "Quick Start/generate_magic_link" {
      input = {email: $input.email}
    } as $token_and_email
  
    // Check that the link exists
    precondition ($token_and_email != null) {
      error = "Magic link could not be created. Try again."
    }
  
    // Create a variable with the API base URL
    var $api_base_url {
      value = $env.$api_baseurl
    }
  
    // Create magic link
    var $magic_link {
      value = $api_base_url
        |concat:"1_start_here_demo_page#/update-password":"/"
        |concat:$token_and_email.token:"?magic_token="
        |concat:$token_and_email.email:""
    }
  
    // Create HTML message to include magic reset password link
    util.template_engine {
      value = """
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Password Reset</title>
        </head>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
          <div style="max-width: 600px; margin: 20px auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
            <h2>Password Reset Request</h2>
            <p>Hello,</p>
            <p>We received a request to reset your password. To proceed, please click the link below:</p>
            <p style="text-align: center; margin: 30px 0;">
              <a href="{{ $var.magic_link }}" style="display: inline-block; padding: 12px 25px; background-color: #007bff; color: #ffffff; text-decoration: none; border-radius: 4px; font-size: 16px;">
                Reset Your Password
              </a>
            </p>
            <p>If you did not request a password reset, please ignore this email.</p>
            <p>Thank you.</p>
          </div>
        </body>
        </html>
        """
    } as $message
  
    // Send email with password reset link
    util.send_email {
      service_provider = "xano"
      subject = "Your password reset request"
      message = $message
    } as $send_email
  }

  response = {
    message: {}|set:"success":true|set:"message":"magic link sent"
  }

  tags = ["xano:quick-start"]
}
---
// Allows user to update the password in the password reset flow
query "reset/update_password" verb=POST {
  api_group = "Authentication"
  auth = ""

  input {
    text password? filters=trim|min:8
    text confirm_password? filters=trim
  }

  stack {
    // Check that the password inputs are matching
    precondition ($input.password == $input.confirm_password) {
      error = "Passwords do not match!"
    }
  
    // Get user record based on the id of the auth token
    db.get "" {
      field_name = "id"
      field_value = $auth.id
    } as $user
  
    // Check that the user record id matches the auth id
    precondition ($user.id == $auth.id) {
      error_type = "accessdenied"
    }
  
    // Update user record with the new password
    db.edit "" {
      field_name = "id"
      field_value = $auth.id
      data = {password: $input.password}
    } as $user
  
    // Create event log
    function.run "Quick Start/log_event" {
      input = {
        user_id : $user.id
        action  : "reset_password"
        metadata: $user
      }
    } as $event_log
  }

  response = {
    message: {"success":"true","message":"Password updated"}
  }

  tags = ["xano:quick-start"]
}
---
// Query all users records
query users verb=GET {
  api_group = "Authentication"

  input {
  }

  stack {
    db.query users {
      return = {type: "list"}
    } as $users
  }

  response = $users
}
---
// Add users record
query users verb=POST {
  api_group = "Authentication"

  input {
    dblink {
      table = "users"
    }
  }

  stack {
    db.add users {
      enforce_hidden_fields = false
      data = {created_at: "now"}
    } as $users
  }

  response = $users
}
---
// Delete users record.
query "users/{users_id}" verb=DELETE {
  api_group = "Authentication"

  input {
    int users_id? filters=min:1
  }

  stack {
    db.del users {
      field_name = "id"
      field_value = $input.users_id
    }
  }

  response = null
}
---
// Get users record
query "users/{users_id}" verb=GET {
  api_group = "Authentication"

  input {
    int users_id? filters=min:1
  }

  stack {
    db.get users {
      field_name = "id"
      field_value = $input.users_id
    } as $users
  
    precondition ($users != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $users
}
---
// Edit users record
query "users/{users_id}" verb=PATCH {
  api_group = "Authentication"

  input {
    int users_id? filters=min:1
    dblink {
      table = "users"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch users {
      field_name = "id"
      field_value = $input.users_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $users
  }

  response = $users
}
---
addon user {
  input {
    int user_id? {
      table = ""
    }
  }

  stack {
    db.query "" {
      where = $db.user.id == $input.user_id
      return = {type: "single"}
    }
  }
}