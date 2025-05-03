import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class Message {
  final String id;
  final String text;
  final bool isUser;
  final String? imageUrl;
  final Timestamp timestamp;
  final bool isLoading;

  Message({
    required this.id,
    required this.text,
    required this.isUser,
    this.imageUrl,
    required this.timestamp,
    this.isLoading = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'imageUrl': imageUrl,
    'timestamp': timestamp,
    'isLoading': isLoading,
  };

  static Message fromJson(Map<String, dynamic> json) {
    var timestamp = json['timestamp'];
    if (timestamp is DateTime) {
      timestamp = Timestamp.fromDate(timestamp);
    } else if (timestamp == null) {
      timestamp = Timestamp.now();
    }
    return Message(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      imageUrl: json['imageUrl'],
      timestamp: timestamp,
      isLoading: json['isLoading'] ?? false,
    );
  }
}

class ChatSession {
  final String id;
  final Timestamp createdAt;
  final List<Message> messages;

  ChatSession({
    required this.id,
    required this.createdAt,
    required this.messages,
  });

  String get title {
    final userMessage = messages.firstWhere(
          (msg) => msg.isUser && msg.text.isNotEmpty,
      orElse: () => Message(
        id: '',
        text: 'New Chat',
        isUser: true,
        timestamp: Timestamp.now(),
      ),
    );
    return userMessage.text.length > 30
        ? '${userMessage.text.substring(0, 30)}...'
        : userMessage.text;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt,
    'messages': messages.map((msg) => msg.toJson()).toList(),
  };

  static ChatSession fromJson(Map<String, dynamic> json, String id) {
    var createdAt = json['createdAt'];
    if (createdAt is DateTime) {
      createdAt = Timestamp.fromDate(createdAt);
    } else if (createdAt == null) {
      createdAt = Timestamp.now();
    }
    final messages = (json['messages'] as List<dynamic>? ?? [])
        .map((msg) => Message.fromJson(msg))
        .toList();
    return ChatSession(
      id: id,
      createdAt: createdAt,
      messages: messages,
    );
  }
}

class CelestialBackground extends StatefulWidget {
  final Widget child;

  const CelestialBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<CelestialBackground> createState() => _CelestialBackgroundState();
}

class _CelestialBackgroundState extends State<CelestialBackground>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Star> stars;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    final random = math.Random();
    stars = List.generate(60, (_) {
      return Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 2 + 0.5,
        opacity: random.nextDouble() * 0.5 + 0.3,
        blinkSpeed: random.nextDouble() * 0.5 + 0.5,
        velocityX: (random.nextDouble() - 0.5) * 0.0002,
        velocityY: (random.nextDouble() - 0.5) * 0.0002,
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A0A0A),
                  Color(0xFF1C1C1E),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                painter: StarfieldPainter(
                  stars: stars,
                  animationValue: _animationController.value,
                ),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class Star {
  double x;
  double y;
  final double size;
  final double opacity;
  final double blinkSpeed;
  final double velocityX;
  final double velocityY;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.blinkSpeed,
    required this.velocityX,
    required this.velocityY,
  });
}

class StarfieldPainter extends CustomPainter {
  final List<Star> stars;
  final double animationValue;

  StarfieldPainter({required this.stars, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      star.x += star.velocityX;
      star.y += star.velocityY;

      if (star.x < 0) star.x += 1.0;
      if (star.x > 1.0) star.x -= 1.0;
      if (star.y < 0) star.y += 1.0;
      if (star.y > 1.0) star.y -= 1.0;

      final paint = Paint()
        ..color = Colors.white.withOpacity(
            (star.opacity + 0.2 * math.sin(animationValue * math.pi * 2 * star.blinkSpeed))
                .clamp(0.2, 0.9))
        ..style = PaintingStyle.fill;

      if (star.size > 1.0) {
        canvas.drawCircle(
          Offset(star.x * size.width, star.y * size.height),
          star.size * 1.5,
          Paint()
            ..color = Colors.white.withOpacity(0.1)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant StarfieldPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class ChatImageRecognitionPage extends StatefulWidget {
  const ChatImageRecognitionPage({Key? key}) : super(key: key);

  @override
  State<ChatImageRecognitionPage> createState() => _ChatImageRecognitionPageState();
}

class _ChatImageRecognitionPageState extends State<ChatImageRecognitionPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;
  List<ChatSession> _chatSessions = [];
  ChatSession? _currentSession;
  User? _user;

  final String apiKey =
      "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";

  final cloudinary = CloudinaryPublic('deimf2by5', 'imagebot', cache: false);

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      _user = FirebaseAuth.instance.currentUser;
      if (_user == null) {
        Navigator.pushReplacementNamed(context, '/auth');
        return;
      }
      await _loadChatSessions();
      if (_chatSessions.isEmpty) {
        _startNewChat();
      } else {
        setState(() {
          _currentSession = _chatSessions.first;
        });
        _scrollToBottom();
      }
    } catch (e) {
      _showErrorSnackBar("Error initializing Firebase: $e");
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<File?> _compressImage(File? file) async {
    if (file == null) return null;

    try {
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        "${file.path}_compressed.jpg",
        quality: 70,
        minWidth: 800,
        minHeight: 800,
      );
      return compressedFile != null ? File(compressedFile.path) : file;
    } catch (e) {
      _showErrorSnackBar("Error compressing image: $e");
      return file;
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _loadChatSessions() async {
    if (_user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('chat_sessions')
          .orderBy('createdAt', descending: true)
          .get();

      final sessions = snapshot.docs.map((doc) {
        return ChatSession.fromJson(doc.data(), doc.id);
      }).toList();

      setState(() {
        _chatSessions = sessions;
      });
    } catch (e) {
      _showErrorSnackBar("Error loading chat sessions: $e");
    }
  }

  Future<void> _saveChatSession(ChatSession session) async {
    if (_user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('chat_sessions')
          .doc(session.id)
          .set(session.toJson());
    } catch (e) {
      _showErrorSnackBar("Error saving chat session: $e");
    }
  }

  Future<void> _deleteChatSession(String sessionId) async {
    if (_user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('chat_sessions')
          .doc(sessionId)
          .delete();

      setState(() {
        _chatSessions.removeWhere((session) => session.id == sessionId);
        if (_currentSession?.id == sessionId) {
          if (_chatSessions.isNotEmpty) {
            _currentSession = _chatSessions.first;
          } else {
            _startNewChat();
          }
        }
      });
    } catch (e) {
      _showErrorSnackBar("Error deleting chat session: $e");
    }
  }

  void _startNewChat() {
    final newSession = ChatSession(
      id: _generateId(),
      createdAt: Timestamp.now(),
      messages: [
        Message(
          id: _generateId(),
          text: "Hey there! 👋 Drop an image or ask me anything. I'm ready to help!",
          isUser: false,
          timestamp: Timestamp.now(),
        ),
      ],
    );

    setState(() {
      _chatSessions.insert(0, newSession);
      _currentSession = newSession;
      _selectedImage = null;
    });
    _saveChatSession(newSession);
    _scrollToBottom();
  }

  void _loadSession(ChatSession session) {
    setState(() {
      _currentSession = session;
      _selectedImage = null;
    });
    _scrollToBottom();
  }

  void _deleteMessage(Message message) {
    setState(() {
      _currentSession!.messages.remove(message);
    });
    _saveChatSession(_currentSession!);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String?> _uploadImageToCloudinary(File image) async {
    try {
      if (!await image.exists()) {
        _showErrorSnackBar("Image file does not exist at path: ${image.path}");
        return null;
      }

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      if (response.secureUrl == null || response.secureUrl!.isEmpty) {
        _showErrorSnackBar("Cloudinary upload succeeded, but no secure URL returned.");
        return null;
      }

      return response.secureUrl;
    } catch (e) {
      _showErrorSnackBar("Error uploading image to Cloudinary: $e");
      return null;
    }
  }

  Future<void> uploadImageAndSaveToChat({
    required String userId,
    required String sessionId,
    required File image,
  }) async {
    try {
      final compressedImage = await _compressImage(image);
      if (compressedImage == null) {
        _showErrorSnackBar("Failed to compress image");
        return;
      }

      final imageUrl = await _uploadImageToCloudinary(compressedImage);
      if (imageUrl == null) {
        _showErrorSnackBar("Failed to upload image to Cloudinary");
        return;
      }

      final message = Message(
        id: _generateId(),
        text: "Just shared this image with you! ✨",
        isUser: true,
        imageUrl: imageUrl,
        timestamp: Timestamp.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .doc(sessionId)
          .update({
        'messages': FieldValue.arrayUnion([message.toJson()]),
      });

      if (_currentSession?.id == sessionId) {
        setState(() {
          _currentSession!.messages.add(message);
          _selectedImage = null;
        });
        _scrollToBottom();
      }
    } catch (e) {
      _showErrorSnackBar("Error in uploadImageAndSaveToChat: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      final compressedImage = await _compressImage(File(pickedFile.path));
      if (compressedImage == null) {
        _showErrorSnackBar("Failed to compress image");
        return;
      }

      if (_user == null || _currentSession == null) {
        _showErrorSnackBar("User or session not available");
        return;
      }

      setState(() {
        _selectedImage = compressedImage;
      });

      await uploadImageAndSaveToChat(
        userId: _user!.uid,
        sessionId: _currentSession!.id,
        image: compressedImage,
      );
    } catch (e) {
      _showErrorSnackBar("Error picking image: $e");
    }
  }

  Future<void> _analyzeImage(String userQuery) async {
    if (_currentSession == null || _currentSession!.messages.isEmpty) {
      _showErrorSnackBar("No chat session available for analysis");
      return;
    }

    final latestImageMessage = _currentSession!.messages
        .lastWhere((msg) => msg.isUser && msg.imageUrl != null, orElse: () => Message(id: '', text: '', isUser: false, timestamp: Timestamp.now()));
    if (latestImageMessage.imageUrl == null) {
      _showErrorSnackBar("No image URL found for analysis");
      return;
    }

    setState(() {
      _isLoading = true;
      _currentSession!.messages.add(
        Message(
          id: _generateId(),
          text: "Working my magic on your image...",
          isUser: false,
          timestamp: Timestamp.now(),
          isLoading: true,
        ),
      );
    });
    _saveChatSession(_currentSession!);
    _scrollToBottom();

    try {
      String prompt = userQuery.isNotEmpty
          ? userQuery
          : "Give a detailed and insightful analysis of this image. Describe what you see, identify objects, people, text, and any interesting or notable elements with an engaging tone.";

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {'url': latestImageMessage.imageUrl}
                }
              ]
            }
          ],
          'max_tokens': 1000,
        }),
      );

      setState(() {
        _currentSession!.messages.removeWhere((message) => message.isLoading);
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final analysisResult = data['choices'][0]['message']['content'];

        setState(() {
          _currentSession!.messages.add(
            Message(
              id: _generateId(),
              text: analysisResult,
              isUser: false,
              timestamp: Timestamp.now(),
            ),
          );
        });
      } else {
        _showErrorSnackBar("Failed to analyze image. Status: ${response.statusCode}, Response: ${response.body}");
        setState(() {
          _currentSession!.messages.add(
            Message(
              id: _generateId(),
              text: "Couldn't analyze the image. The API responded with an error. Please ensure the image URL is accessible and your API key supports vision capabilities.",
              isUser: false,
              timestamp: Timestamp.now(),
            ),
          );
        });
        throw Exception('Failed to analyze image: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _currentSession!.messages.removeWhere((message) => message.isLoading);
        _isLoading = false;
        _currentSession!.messages.add(
          Message(
            id: _generateId(),
            text: "Error processing image. Please try again or check your API configuration.",
            isUser: false,
            timestamp: Timestamp.now(),
          ),
        );
      });
      _showErrorSnackBar("Analysis error: $e");
    }
    _saveChatSession(_currentSession!);
    _scrollToBottom();
  }

  Future<void> _handleTextQuery(String userMessageText) async {
    setState(() {
      _isLoading = true;
      _currentSession!.messages.add(
        Message(
          id: _generateId(),
          text: "Thinking...",
          isUser: false,
          timestamp: Timestamp.now(),
          isLoading: true,
        ),
      );
    });
    _saveChatSession(_currentSession!);
    _scrollToBottom();

    try {
      // Check if the user message might be referring to an image
      final imageKeywords = ['this', 'image', 'picture', 'photo'];
      bool mightReferToImage = imageKeywords.any((keyword) => userMessageText.toLowerCase().contains(keyword));

      // Find the most recent image message if the user might be referring to an image
      Message? latestImageMessage;
      if (mightReferToImage) {
        latestImageMessage = _currentSession!.messages
            .lastWhere((msg) => msg.isUser && msg.imageUrl != null, orElse: () => Message(id: '', text: '', isUser: false, timestamp: Timestamp.now()));
        if (latestImageMessage.imageUrl == null) {
          mightReferToImage = false; // No recent image found
        }
      }

      // If the message refers to an image, redirect to _analyzeImage
      if (mightReferToImage && latestImageMessage!.imageUrl != null) {
        setState(() {
          _currentSession!.messages.removeWhere((message) => message.isLoading);
          _isLoading = false;
        });
        await _analyzeImage(userMessageText);
        return;
      }

      // Otherwise, proceed with a text-only query, including recent chat context
      // Limit to the last 5 messages to avoid token limits
      final recentMessages = _currentSession!.messages
          .reversed
          .take(5)
          .toList()
          .reversed
          .map((msg) => {
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.imageUrl != null
            ? [
          {'type': 'text', 'text': msg.text},
          {
            'type': 'image_url',
            'image_url': {'url': msg.imageUrl}
          }
        ]
            : msg.text,
      })
          .toList();

      // Add the current user message
      recentMessages.add({
        'role': 'user',
        'content': userMessageText,
      });

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': recentMessages,
          'max_tokens': 1000,
        }),
      );

      setState(() {
        _currentSession!.messages.removeWhere((message) => message.isLoading);
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = data['choices'][0]['message']['content'];

        setState(() {
          _currentSession!.messages.add(
            Message(
              id: _generateId(),
              text: responseText,
              isUser: false,
              timestamp: Timestamp.now(),
            ),
          );
        });
      } else {
        setState(() {
          _currentSession!.messages.add(
            Message(
              id: _generateId(),
              text: "Couldn't process your request. Please try again. (Error: ${response.statusCode})",
              isUser: false,
              timestamp: Timestamp.now(),
            ),
          );
        });
        throw Exception('Failed to process text query: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _currentSession!.messages.removeWhere((message) => message.isLoading);
        _isLoading = false;
        _currentSession!.messages.add(
          Message(
            id: _generateId(),
            text: "Error processing request. Please try again.",
            isUser: false,
            timestamp: Timestamp.now(),
          ),
        );
      });
      _showErrorSnackBar("Query error: $e");
    }
    _saveChatSession(_currentSession!);
    _scrollToBottom();
  }

  Future<void> _handleSendPressed() async {
    final userMessageText = _messageController.text.trim();

    if (userMessageText.isEmpty && _selectedImage == null) {
      return;
    }

    try {
      if (userMessageText.isNotEmpty) {
        setState(() {
          _currentSession!.messages.add(
            Message(
              id: _generateId(),
              text: userMessageText,
              isUser: true,
              timestamp: Timestamp.now(),
            ),
          );
        });
        _saveChatSession(_currentSession!);

        _messageController.clear();
        _scrollToBottom();

        if (_selectedImage != null) {
          await uploadImageAndSaveToChat(
            userId: _user!.uid,
            sessionId: _currentSession!.id,
            image: _selectedImage!,
          );
          await _analyzeImage(userMessageText);
        } else {
          await _handleTextQuery(userMessageText);
        }
      } else if (_selectedImage != null) {
        await uploadImageAndSaveToChat(
          userId: _user!.uid,
          sessionId: _currentSession!.id,
          image: _selectedImage!,
        );
        await _analyzeImage(userMessageText);
      }
    } catch (e) {
      _showErrorSnackBar("Error sending message: $e");
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Show Me Something Amazing',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImagePickerOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Snap Now',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildImagePickerOption(
                    icon: Icons.photo_library_rounded,
                    label: 'From Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.spaceGrotesk(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.isUser;
    final bubbleColor = isUser
        ? Colors.white.withOpacity(0.2)
        : const Color(0xFF1C1C1E).withOpacity(0.9);
    final textColor = Colors.white;
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final borderRadius = isUser
        ? const BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
      bottomLeft: Radius.circular(20),
      bottomRight: Radius.circular(4),
    )
        : const BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(20),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (message.imageUrl != null)
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
                maxHeight: 200,
              ),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  message.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, color: Colors.red);
                  },
                ),
              ),
            ),
          GestureDetector(
            onLongPress: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text(
                    'Delete Message',
                    style: GoogleFonts.spaceGrotesk(color: Colors.white),
                  ),
                  content: Text(
                    'Are you sure you want to delete this message?',
                    style: GoogleFonts.spaceGrotesk(color: Colors.grey.shade400),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.spaceGrotesk(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _deleteMessage(message);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Delete',
                        style: GoogleFonts.spaceGrotesk(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: message.isLoading ? Colors.transparent : bubbleColor,
                borderRadius: borderRadius,
                boxShadow: message.isLoading
                    ? []
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: message.isLoading ? EdgeInsets.zero : const EdgeInsets.all(14),
              child: message.isLoading
                  ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Lottie.network(
                  'https://assets6.lottiefiles.com/packages/lf20_pKiaUR.json',
                  width: 60,
                  height: 40,
                ),
              )
                  : SelectableText(
                message.text,
                style: GoogleFonts.spaceGrotesk(
                  color: textColor,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      _user = null;
      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (Route<dynamic> route) => false);
    } catch (e) {
      _showErrorSnackBar("Error logging out: $e");
    }
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        Map<String, List<ChatSession>> groupedSessions = {
          'Today': [],
          'Yesterday': [],
          'Older': [],
        };

        for (var session in _chatSessions) {
          DateTime sessionDate;
          try {
            sessionDate = session.createdAt.toDate();
          } catch (e) {
            sessionDate = DateTime.now();
            _showErrorSnackBar("Error parsing session date: $e");
          }
          final sessionDay = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
          if (sessionDay == today) {
            groupedSessions['Today']!.add(session);
          } else if (sessionDay == yesterday) {
            groupedSessions['Yesterday']!.add(session);
          } else {
            groupedSessions['Older']!.add(session);
          }
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chats',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Start New Chat',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _startNewChat();
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Logout',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _logout();
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const Divider(
                color: Colors.white10,
                height: 24,
              ),
              Expanded(
                child: ListView(
                  children: groupedSessions.entries
                      .where((entry) => entry.value.isNotEmpty)
                      .expand((entry) {
                    return [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          entry.key,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      ...entry.value.map((session) {
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: Text(
                            session.title,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: Colors.white,
                              size: 20,
                            ),
                            color: const Color(0xFF1C1C1E).withOpacity(0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteChatSession(session.id);
                                Navigator.pop(context);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Delete',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.redAccent,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _loadSession(session);
                          },
                          tileColor: _currentSession?.id == session.id
                              ? Colors.white.withOpacity(0.1)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      }),
                    ];
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return CelestialBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          toolbarHeight: 0,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1C1C1E).withOpacity(0.9),
                        const Color(0xFF1C1C1E).withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Tooltip(
                            message: 'Chats',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showChatOptions,
                                borderRadius: BorderRadius.circular(28),
                                splashColor: Colors.white.withOpacity(0.4),
                                highlightColor: Colors.white.withOpacity(0.2),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C1C1E).withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'GenThinks',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ).animate()
                                    .fadeIn(duration: const Duration(milliseconds: 600))
                                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
                                const SizedBox(height: 4),
                                Text(
                                  'Explore the Story Behind Every Pixel',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontStyle: FontStyle.normal,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey.shade400,
                                  ),
                                ).animate()
                                    .fadeIn(
                                    delay: const Duration(milliseconds: 300),
                                    duration: const Duration(milliseconds: 800))
                                    .slideY(begin: 0.2, end: 0),
                              ],
                            ),
                          ),
                          Tooltip(
                            message: 'About',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                      child: Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.9),
                                        child: Padding(
                                          padding: const EdgeInsets.all(24.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(10),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: const Icon(
                                                      Icons.auto_awesome,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      'About GenThinks',
                                                      style: GoogleFonts.spaceGrotesk(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Unlock the hidden stories in your photos! Powered by cutting-edge AI vision technology, GenThinks sees what human eyes might miss. Upload any image or ask any question – from identifying objects to answering queries with intelligence.',
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 15,
                                                  height: 1.5,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    'Let\'s explore!',
                                                    style: GoogleFonts.spaceGrotesk(
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.black,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(28),
                                splashColor: Colors.white.withOpacity(0.4),
                                highlightColor: Colors.white.withOpacity(0.2),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C1C1E).withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _currentSession == null
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _currentSession!.messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_currentSession!.messages[index]);
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: 12 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E).withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, -3),
                      ),
                    ],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Container(
                          height: 44,
                          width: 44,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              _selectedImage != null ? Icons.check_circle : Icons.add_photo_alternate,
                              color: Colors.white,
                            ),
                            onPressed: _showImagePickerOptions,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: _selectedImage != null
                                    ? 'What would you like to know about this image?'
                                    : 'Ask me anything or add an image...',
                                hintStyle: GoogleFonts.spaceGrotesk(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                              ),
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              maxLines: null,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _handleSendPressed(),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _handleSendPressed,
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}