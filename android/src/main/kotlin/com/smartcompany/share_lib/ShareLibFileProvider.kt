package com.smartcompany.share_lib

import androidx.core.content.FileProvider

/** Host 앱의 다른 FileProvider와 클래스명이 겹치지 않도록 분리 */
class ShareLibFileProvider : FileProvider()
