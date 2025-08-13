
#### Kerberos+Nginx 实现 Ollama 的 AD 用户认证
- 假定访问的主机名为： ollama.mydom.local (mydom.local 为AD域的域名)
- 需要注册 SPN，`klist`  命令应该能看到 HTTP/ollama.mydom.local@MYDOM.LOCAL 这条记录
- 编译 Nginx 的 kerberos 支持， 编译时应该指定：--add-module=spnego-http-auth-nginx-module
- Nginx 配置：
```nginx
location /{
   proxy_pass http://127.0.0.1:11434;
   proxy_set_header Host 127.0.0.1:11434;
   auth_gss on;
   auth_gss_keytab /etc/krb5.keytab;
   auth_gss_service_name http/ollama.mydom.local;
   auth_gss_allow_basic_fallback off;
   auth_gss_authorized_principal USERNAME;
}
```
- 启动 Electron 客户端（如 Chatbox-xxx.AppImage)时，命令行添加参数：--auth-server-whitelist='*mydom.local'  --auth-negotiate-delegate-whitelist='*mydom.local'
- 浏览器插件 Page-Assist 不需要额外的设置，因为操作系统的浏览器启动时就带有 Keberos 认证（ Windows 和 UOS 都加 AD域控），只是在 Ollama 高级配置那里，启用 CORS (自定义来源为 127.0.0.1:11434)即可。
- 计划把访问资源的 IP 配置到 HAProxy 上，后台每台工作站都配置 Nginx+Ollama，Nginx 上配置仅允许 HAProxy IP 访问。

