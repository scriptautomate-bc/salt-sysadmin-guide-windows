create_hello_world_file:
  file.managed:
    - name: 'C:\helloworld.txt'
    - contents: 'Hello World from the Rocky Linux Salt Master!'
