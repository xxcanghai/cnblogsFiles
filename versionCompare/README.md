# versionCompare 版本号比较工具
提供了比较多点分割形式的版本号(0.1.2.3)比较功能。

按照点分割后逐级比较，不存在的按0处理。

空字符串小于非空字符串。

# Demo
[http://xxcanghai.github.io/cnblogsFiles/versionCompare/index.html](http://xxcanghai.github.io/cnblogsFiles/versionCompare/index.html)

# Test
'1' = '1'

'1' = '1.0'

'1' = '1.0.0'

'1.0' = '1'

'1.0' = '1.0'

'1.0.0' = '1.0'

'1.1' > '1'

'1.1' < '1.1.1'

'1.1' = '1.1.0'

'1.1.0' = '1.1'

'0.1.2' < '0.1.2.3'

'0.1.2' < '0.1.3'

'0.1.2' < '0.2.2'

'0.1.2' < '1.1.2'

'10.20.30' = '10.20.30'

'10.20.30' < '10.20.30.0.0.0.1'

'0.10.20.30' < '10.20.30'

'1' > ''

'' < '1'

'' < '0'

'' = ''

其他测试请点击[Demo](http://xxcanghai.github.io/cnblogsFiles/versionCompare/index.html)

# Blog
相关博客文章：
[http://www.cnblogs.com/xxcanghai/p/6007136.html](http://www.cnblogs.com/xxcanghai/p/6007136.html)