(require "ni/setup")

(provide "ni/update-xyzzy")
(in-package "netinst")

(defvar *latest-xyzzy-info-url*
  "https://raw.github.com/mumurik/xyzzy/master/latest-xyzzy-info.l"
  "�ŐV�ł�xyzzy�̔z�z�̏��̓������t�@�C���ւ�URL�Bpackages.l�Ɠ����t�H�[�}�b�g��z��B")

(defvar *installed-xyzzy-info-file*
  (merge-pathnames "installed-xyzzy-info.l" *base-directory*)
  "���݃C���X�g�[������Ă���xyzzy��packages.l�����̃t�@�C���̕ۑ�����Ă���p�X�B
����C���X�g�[�����͑��݂��Ȃ��̂Œ��ӁB")

(defvar *latest-xyzzy-info-file*
  (merge-pathnames "latest-xyzzy-info.l" *base-directory*)
  "�ŐV��packages.l�����̃t�@�C���̕ۑ�����Ă���p�X�B")

(defvar *xhr* nil)

(defun safe-data-read (file)
  (when (file-exist-p file)
    (when (check-read-time-eval file)
      (ni-error "�s���ȃt�@�C���ł�: ~%~A" file))
    (data-read-from-file file)))

(defun load-installed-xyzzy-info ()
"�C���X�g�[������Ă�xyzzy�Ɋւ���site��Ԃ��Bsite-*�ŗv�f�ɂ̓A�N�Z�X�ł���B
src�������Ă��鎖�͕ۏႳ��Ȃ��B"
  (safe-data-read *installed-xyzzy-info-file*))

(defun load-latest-xyzzy-info ()
"�ŐV��xyzzy�Ɋւ���site��Ԃ��Bsite-*�ŗv�f�ɂ̓A�N�Z�X�ł���B
src�������Ă��鎖�͕ۏႳ��Ȃ��B"
  (safe-data-read *latest-xyzzy-info-file*))



(defun https-get-to-file (url file)
"url�̓��e��file�Ƀo�C�i���ŕۑ��Bfile�̓t���p�X
��U�������ɑS�ēǂݍ��ނ̂ő傫�ȃt�@�C���ł͎g��Ȃ��ł��������B"
  (unless *xhr*
    (setq *xhr* (ole-create-object "WinHttp.WinHttpRequest.5.1")))
  (long-operation
    (ole-method *xhr* 'open "GET" url nil) ;; non-blocking and just sleep never change state. so use as blocking.
    (ole-putprop *xhr* 'Option t 6) ; redirect
    (ole-method *xhr* 'send)
    (if (eq (ole-method *xhr* 'status) 302) ; handle redirect only once because it's enough for most of the case.
	(progn
	  (ole-method *xhr* 'open "GET" (ole-method *xhr* 'GetResponseHeader "location") nil)
	  (ole-method *xhr* 'send)))
    (if (not (eq (ole-method *xhr* 'status) 200))
	(progn
	  (message-box "�A�[�J�C�u�̎擾�Ɏ��s���܂���")
	  ; for debug (setq *xhr* nil)
	  nil)
      (let ((dir (directory-namestring file))
	    (stream (ole-create-object "ADODB.Stream")))
	(unless (file-exist-p dir)
	  (create-directory dir))
	(ole-putprop stream 'Type 1)
	(ole-method stream 'Open)
	(ole-method stream 'Write (ole-method *xhr* 'responseBody))
	(ole-method stream 'SaveToFile file 2) ;; overwrite
	(ole-method stream 'Close)
	t))))
  
(defun update-latest-xyzzy-info ()
"�ŐV�ł�packages.l�����̃t�@�C�����_�E�����[�h�B"
  (https-get-to-file *latest-xyzzy-info-url* *latest-xyzzy-info-file*)
  t)

(defun newer-version-exist-p ()
"�ŐV�ł�md5���������V�����ł�����Ƃ݂Ȃ��B�������[�J����md5��������ΐV�����ł�����Ƃ݂Ȃ��B
����C���X�g�[�����ɂ�md5�������̂ł���t�B"
  (let ((installed (installed-xyzzy-app)))
    (if installed
	(not (equal (app-md5 (installed-xyzzy-app))
		    (app-md5 (latest-xyzzy-app))))
	t)))

(defun xyzzy-info-to-app (info)
"xyzzy�Ɋւ���site����xyzzy��packages�̗v�f��Ԃ��B��Ԗڂ̗v�f�ƌ��ߑł�"  
  (if info
      (car (site-apps info))))

(defun latest-xyzzy-app ()
  (xyzzy-info-to-app (load-latest-xyzzy-info)))

(defun installed-xyzzy-app ()
  (xyzzy-info-to-app (load-installed-xyzzy-info)))

(defun fetch-latest-xyzzy-archive (latestapp)
"�ŐV��archive���擾����md5���`�F�b�N���A��v������t��Ԃ��B
install-app-fetch�ƂقƂ�Ǔ��������ǁA�ߋ���archive�͊��ɍ폜�ς݂Ȃ̂��Ⴄ�B"
  (let ((file (app-src-file latestapp)))
    (unless (https-get-to-file (app-src latestapp) file)
      (return-from fetch-latest-xyzzy-archive))
    (if (app-src-md5sum-check latestapp)
	t
      (progn
	(delete-file file)
	nil))))

(defun update-xyzzy ()
  (let ((latestapp (latest-xyzzy-app)))
    (unless (fetch-latest-xyzzy-archive latestapp)
      (return-from update-xyzzy))
    (extract-archive (app-src-file latestapp) (si:system-root))
    (delete-file (app-src-file latestapp)
    (copy-file *latest-xyzzy-info-file* *installed-xyzzy-info-file* :if-exists :overwrite) 
    (case (message-box "����N������xyzzy�͍X�V����܂��B�������ċN�����܂����H" nil
		       '(:yes-no :question :button1))
      (:yes (ed:restart-for-update))
      (:no nil)))))
  


(defun editor::check-update()
  (interactive)
  (update-latest-xyzzy-info)
  (if (newer-version-exist-p)
      (case (message-box "�V�����o�[�W����������܂����B�X�V���܂����H" nil
			 '(:yes-no :question :button1))
	(:yes (update-xyzzy))
	(:no (return-from check-update)))
    (progn
     (message-box "���g���̃o�[�W�����͍ŐV�o�[�W�����ł��B")
      (return-from check-update))))


