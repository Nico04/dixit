using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Blurhash;
using System.IO;
using System.Linq;
using System.Text.Json;

namespace Blurhash {
    class Program {
        static readonly string[] ValidExtensions = { ".jpg", ".png" };
        static readonly JsonSerializerOptions jsonOptions = new JsonSerializerOptions {
            IgnoreNullValues = true,
            WriteIndented = true,            
        };

        static void Main(string[] args) {
            if (args.Length < 1) {
                Console.WriteLine("Folder path argument missing");
                return;
            }

            try {
                // Get files list
                var folderPath = args[0];
                Console.WriteLine($"Searching files in : {folderPath}");

                var filesPath = Directory.GetFiles(folderPath);

                // Filter
                filesPath = filesPath.Where((path) => ValidExtensions.Contains(Path.GetExtension(path).ToLower())).ToArray();

                // Create blurhash encoder
                var blurHashEncoder = new Encoder();

                // Build cards
                var cards = new List<Card>();
                for (int i = 0; i < filesPath.Length; i++) {
                    Console.Write($"\r{i} / {filesPath.Length}   ");

                    string filePath = filesPath[i];
                    string blurHash;

                    using (var image = new Bitmap(filePath))
                        blurHash = blurHashEncoder.Encode(image, 4, 3);

                    cards.Add(new Card(i, Path.GetFileName(filePath), blurHash));
                }

                // Serialize
                var jsonString = JsonSerializer.Serialize(cards, jsonOptions);
                var outputFilePath = Path.Combine(folderPath, "cards.json");
                File.WriteAllText(outputFilePath, jsonString);
                Console.WriteLine($"\nSaved : {outputFilePath}");

            } catch (Exception e) {
                Console.WriteLine(@$"/!\ Error /!\ : {e}");
            }

            Console.WriteLine("Done");
        }
    }

    class Card {
        public int id { get; set; }
        public string filename { get; set; }
        public string blurHash { get; set; }

        public Card(int id, string filename, string blurHash) {
            this.id = id;
            this.filename = filename;
            this.blurHash = blurHash;
        }
    } 
}
