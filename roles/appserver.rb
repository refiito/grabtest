name "appserver"
run_list "recipe[helloapp]"
override_attributes(
  nginx: {
    default_root: "/var/www/html"
  }
)